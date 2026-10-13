"""Read-only APK inventory and selected Hermes v96 string evidence.
No execution, network requests, credential extraction, or full string dump.
Usage: python tools/inspect_apk.py path/to.apk > report.json
Optional manifest decoding: pip install androguard
"""
import argparse
import hashlib
import json
import re
import struct
import zipfile

EVIDENCE = (
    'chatV3ControllerCreateSummary', 'chatV3ControllerUpdateSummary',
    'chatV3ControllerUpdateLastSummary', 'chatV3ControllerDeleteSummary',
    'chatV3ControllerReadSummaries', 'chatV3ControllerGetSummariesVersion',
    'chatV3ControllerBranchChat', 'chatV3ControllerApplySnapshot',
    'chatV3ControllerApplyReplacementModel', 'ChatModelSelectBottomSheet',
    'useChatModelErrorsPolling', 'useStreamingState', 'useCreateBranch',
    'regenerateSituationImage', 'EndingCollectionScreen', 'EndingDetailScreen',
    '/ooc-gen/situation-images/generate', '/ooc-gen/v3/chat-models',
    '/ooc-gen/v3/chat-models/errors/config', '/summaries', '/summaries/version',
    '/snapshot/apply', '/branch', 'chatModel.maxOutput is required',
)


def hermes_strings(data):
    if len(data) < 128 or struct.unpack_from('<Q', data)[0] != 0x1F1903C103BC1FC6:
        raise ValueError('Not a supported Hermes bytecode file')
    h = struct.unpack_from('<30I', data)
    if h[2] != 96:
        raise ValueError('Only Hermes bytecode version 96 is supported')
    if h[8] != len(data):
        raise ValueError('Bytecode file length mismatch')
    pos = 128 + h[10] * 16 + h[11] * 4 + h[12] * 4
    overflow = pos + h[13] * 4
    storage = overflow + h[14] * 8
    end = storage + h[15]
    if end > len(data):
        raise ValueError('String table exceeds file bounds')
    values = []
    for i in range(h[13]):
        e = struct.unpack_from('<I', data, pos + i * 4)[0]
        utf16, offset, length = e & 1, (e >> 1) & 0x7FFFFF, e >> 24
        if length == 255:
            if offset >= h[14]:
                raise ValueError('Invalid overflow index')
            offset, length = struct.unpack_from('<II', data, overflow + offset * 8)
        size = length * (2 if utf16 else 1)
        if offset + size > h[15]:
            raise ValueError('String exceeds storage bounds')
        raw = data[storage + offset:storage + offset + size]
        values.append(raw.decode('utf-16le' if utf16 else 'utf-8', errors='replace'))
    return values


def inspect(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(chunk)
    result = {'sha256': digest.hexdigest(), 'method': 'static; no app execution'}
    with zipfile.ZipFile(path) as apk:
        names = apk.namelist()
        result['entry_count'] = len(names)
        result['dex_files'] = [n for n in names if re.fullmatch(r'classes\d*\.dex', n)]
        result['native_library_count'] = sum(n.startswith('lib/') and n.endswith('.so') for n in names)
        result['recognized_model_files'] = [n for n in names if re.search(r'\.(gguf|onnx|tflite|safetensors|pte|task)$', n)]
        if 'assets/index.android.bundle' in names:
            bundle = apk.read('assets/index.android.bundle')
            values = hermes_strings(bundle)
            result['hermes'] = {'version': 96, 'bundle_bytes': len(bundle),
                'string_count': len(values),
                'strings_with_decode_replacements': sum('\ufffd' in s for s in values),
                'evidence': [{'id': i, 'value': s} for i, s in enumerate(values) if s in EVIDENCE]}
        if 'assets/sentry-external-modules.txt' in names:
            modules = apk.read('assets/sentry-external-modules.txt').decode().splitlines()
            result['selected_modules'] = [m for m in modules if m.startswith((
                'com.facebook.react:react-android:', 'com.facebook.hermes:hermes-android:',
                'com.android.billingclient:billing:', 'com.appsflyer:af-android-sdk:',
                'io.sentry:', 'com.google.firebase:firebase-messaging:'))]
    try:
        from loguru import logger
        logger.remove()
        from androguard.core.apk import APK
        app = APK(path)
        attrs = app.get_android_manifest_xml().find('application').attrib
        ns = '{http://schemas.android.com/apk/res/android}'
        result['manifest'] = {'package': app.get_package(),
            'version_name': app.get_androidversion_name(), 'version_code': app.get_androidversion_code(),
            'min_sdk': app.get_min_sdk_version(), 'target_sdk': app.get_target_sdk_version(),
            'main_activity': app.get_main_activity(), 'permissions': sorted(app.get_permissions()),
            'allow_backup': attrs.get(ns + 'allowBackup'),
            'uses_cleartext_traffic': attrs.get(ns + 'usesCleartextTraffic')}
    except ImportError:
        result['manifest'] = {'status': 'Install optional androguard to decode manifest'}
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk')
    args = parser.parse_args()
    print(json.dumps(inspect(args.apk), indent=2))
