"""Durable local pilot store; replace with PostgreSQL for production."""
import json
import sqlite3
from contextlib import contextmanager

class Conflict(ValueError):
    pass

class Store:
    def __init__(self, path):
        self.path = str(path)
        with self.connect() as db:
            db.executescript("""
            CREATE TABLE IF NOT EXISTS branches(
              owner TEXT NOT NULL, id TEXT NOT NULL, version INTEGER NOT NULL,
              state TEXT NOT NULL, PRIMARY KEY(owner,id));
            CREATE TABLE IF NOT EXISTS requests(
              owner TEXT NOT NULL, branch TEXT NOT NULL, request TEXT NOT NULL,
              action TEXT NOT NULL, result TEXT NOT NULL,
              PRIMARY KEY(owner,branch,request));
            """)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        try:
            yield db
            db.commit()
        except BaseException:
            db.rollback()
            raise
        finally:
            db.close()

    def load(self, owner, branch):
        with self.connect() as db:
            row = db.execute("SELECT version,state FROM branches WHERE owner=? AND id=?",
                             (owner, branch)).fetchone()
        if not row:
            raise KeyError("Adventure not found")
        return row[0], json.loads(row[1])

    def replay(self, owner, branch, request, action):
        with self.connect() as db:
            row = db.execute("SELECT action,result FROM requests WHERE owner=? AND branch=? AND request=?",
                             (owner, branch, request)).fetchone()
        if row:
            if row[0] != action:
                raise Conflict("Request ID already used for a different action")
            return json.loads(row[1])
        return None

    def create(self, owner, branch, state):
        with self.connect() as db:
            db.execute("INSERT INTO branches VALUES(?,?,0,?)",
                       (owner, branch, json.dumps(state)))

    def commit(self, owner, branch, version, request, action, state, result):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT action,result FROM requests WHERE owner=? AND branch=? AND request=?",
                             (owner, branch, request)).fetchone()
            if row:
                if row[0] != action:
                    raise Conflict("Request ID already used for a different action")
                return json.loads(row[1])
            updated = db.execute("UPDATE branches SET version=version+1,state=? WHERE owner=? AND id=? AND version=?",
                                 (json.dumps(state), owner, branch, version))
            if updated.rowcount != 1:
                raise Conflict("Adventure changed; reload before retrying")
            db.execute("INSERT INTO requests VALUES(?,?,?,?,?)",
                       (owner, branch, request, action, json.dumps(result)))
        return result
