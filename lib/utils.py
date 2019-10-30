#
# Utility functions to read and write json and jsonl files
#
import bz2
import codecs
import json
import os

from frozendict import frozendict


def write_json_file(obj, path):
  '''Dump an object and write it out as json to a file.'''
  f = codecs.open(path, 'w', 'utf-8')
  f.write(json.dumps(obj, ensure_ascii=False))
  f.close()


def write_json_lines_file(ary_of_objects, path):
  '''Dump a list of objects out as a json lines file.'''
  f = codecs.open(path, 'w', 'utf-8')
  for row_object in ary_of_objects:
    json_record = json.dumps(row_object, ensure_ascii=False)
    f.write(json_record + "\n")
  f.close()


def read_json_file(path):
  '''Turn a normal json file (no CRs per record) into an object.'''
  text = codecs.open(path, 'r', 'utf-8').read()
  return json.loads(text)


def read_json_lines_bz(path):
  '''Read a JSON Lines bzip compressed file'''
  ary = []
  with bz2.open(path, "rt") as bz_file:
    for line in bz_file:
      record = json.loads(line.rstrip("\n|\r"))
      ary.append(record)
  return ary


def read_json_lines(path):
  '''Read a JSON Lines file'''
  ary = []
  with codecs.open(path, "r", "utf-8") as f:
    for line in f:
      record = json.loads(line.rstrip("\n|\r"))
      ary.append(record)
  return ary


def read_json_lines_file(path):
  '''Turn a json cr file (CRs per record) into an array of objects'''
  ary = []

  if os.path.isdir(path):
    for (dirpath, dirnames, filenames) in os.walk(path):
        for filename in filenames:
          full_path = f'{dirpath}/{filename}'
          if full_path.endswith('json') or full_path.endswith('jsonl'):
            ary.extend(
              read_json_lines(full_path)
            )
          if path.endswith('bz2'):
            ary.extend(
              read_json_lines_bz(full_path)
            )
  else:
    if path.endswith('bz2'):
      ary.extend(
        read_json_lines_bz(path)
      )
    else:
      ary.extend(
        read_json_lines(path)
      )
  return ary


class FrozenEncoder(json.JSONEncoder):
  def default(self, obj):
    if isinstance(obj, frozendict):
      return dict(obj)
    if isinstance(obj, frozenset):
      return list(obj)
    # Let the base class default method raise the TypeError
    return json.JSONEncoder.default(self, obj)
