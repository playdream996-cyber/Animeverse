# Visual design pass

Discovery now uses an editorial serif headline, an illustrated feature card with a single clear action, quieter companion metadata, and consistent poster cards. Optional reference refresh lives in the help menu rather than the discovery feed. All reference fixtures remain independently removable.

The reader shares the editorial scene typography, rounded choice surfaces and restrained accent color. Story details use a companion card; bookmarks show actual covers. Creator landing cards and a segmented studio progress bar match the same visual system. Category labels explicitly use Inter to ensure consistent font rendering.

No new runtime dependencies, network requests, animation controllers or unbounded image decodes were added. Existing bounded history, leaf reply notifier, save coalescing and disposal protections remain. Automated tests and phone renders validate layout and interactions; device profiling remains necessary for native performance acceptance.
