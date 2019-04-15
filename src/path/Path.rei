/**
 * Copyright 2004-present Facebook. All Rights Reserved.
 *
 * @emails oncall+ads_front_end_infra
 */;

/**

`Path` is a library for creating and operating on file paths consistently on
all platforms.

`Path` works exactly the same on Windows, Linux, and OSX, instead of adjusting
behavior based on your current OS

*/;

type relative;
type absolute;
/**
A file system path, parameterized on the kind of file system path,
`Path.t(relative)` or `Path.t(absolute)`.
 */
type t('kind);

/**
Used to query whether or not a path is absolute or relative.
Use seldomly.
*/
type detection =
  | Absolute(t(absolute))
  | Relative(t(relative));

let drive: string => t(absolute);
let root: t(absolute);
let home: t(relative);
let dot: t(relative);

/**
Queries whether a path is absolute or relative. Use seldomly, and
typically only on end-user input. Once detected, keep use the
`t(absolute)/t(relative)` as the primary path passed around.
Raises Invalid_argument if the path is invalid.
*/
let detectExn: string => detection;

/**
Same as `detectExn`, but instead of raising on an invalid path, returns an
`option(detection)`.
*/
let detect: string => option(detection);

/**
 Prints absolute `Path.t` as strings, always removes the final `/` separator.
 */
let toString: t(absolute) => string;

/**
 Prints any `Path.t` for debugging, always removes the final `/` separator
 except in the case of the empty relative paths `./`, `~/`.
 */
let toDebugString: t('kind) => string;

/**
Parses an absolute path into a `Path.t(absolute)` or returns `None` if the path
is not a absolute, yet still valid. Raises Invalid_argument if the path is
invalid.
 */
let absolute: string => option(t(absolute));
/**
 Parses a relative path into a `Path.t(relative)` or returns `None` if the path
 is not a valid.
 */
let relative: string => option(t(relative));

/**
 Same as `Path.absolute` but raises a Invalid_argument if argument is not a
 valid absolute path.
 */
let absoluteExn: string => t(absolute);

/**
 Same as `Path.relative` but raises a Invalid_argument if argument is not a
 valid relative path.
 */
let relativeExn: string => t(relative);

/**
Creates a relative path from two paths, which is the relative path that is
required to arive at the `dest`, if starting from `source` directory. The
`source` and `dest` must both be `t(absolute)` or `t(relative)`, but the
returned value is always of type `t(relative)`.

If `source` and `dest` are relative, it is assumed that the two relative paths
are relative to the same yet-to-be-specified absolute path.

relativize(~source=/a, ~dest=/a)                == ./
relativize(~source=/a/b/c/d /a/b/qqq            == ../c/d
relativize(~source=/a/b/c/d, ~dest=/f/f/zzz)    == ../../../../f/f/zz
relativize(~source=/a/b/c/d, ~dest=/a/b/c/d/q)  == ../q
relativize(~source=./x/y/z, ~dest=./a/b/c)      == ../../a/b/c
relativize(~source=./x/y/z, ~dest=../a/b/c)     == ../../../a/b/c

Unsupported:
`relativize` only accepts `source` and `dest` of the same kind of path because
the following are meaningless:

relativize(~source=/x/y/z, ~dest=./a/b/c) == ???
relativize(~source=./x/y/z, ~dest=/a/b/c) == ???

Exceptions:
If it is impossible to create a relative path from `soure` to `dest` an
exception is raised.
If `source`/`dest` are absolute paths, the drive must match or an exception is
thrown. If `source`/`dest` are relative paths, they both must be relative to
`"~"` vs. `"."`. If both are relative, but the source has more `..` than the
dest, then it is also impossible to create a relative path and an exception is
raised.

relativize(~source=./foo/bar, ~dest=~/foo/bar)       == raise(Invalid_argument)
relativize(~source=~/foo/bar, ~dest=./foo/)          == raise(Invalid_argument)
relativize(~source=C:/foo/bar, ~dest=/foo/bar)       == raise(Invalid_argument)
relativize(~source=C:/foo/bar, ~dest=F:/foo/bar)     == raise(Invalid_argument)
relativize(~source=/foo/bar, ~dest=C:/foo/)          == raise(Invalid_argument)
relativize(~source=../x/y/z, ~dest=./a/b/c)          == raise(Invalid_argument)
relativize(~source=../x/y/z, ~dest=../foo/../a/b/c)  == raise(Invalid_argument)
*/
let relativizeExn: (~source: t('kind), ~dest: t('kind)) => t(relative);

/**
 Accepts any `Path.t` and returns a `Path.t` of the same kind.  Relative path
 inputs return relative path outputs, and absolute path inputs return absolute
 path outputs.
 */
let dirName: t('kind) => t('kind);

/**
 Accepts any `Path.t` and returns the final segment in its path string, or
 `None` if there are no segments in its path string.

    Path.baseName(Path.At(Path.dot /../ ""))
    None

    Path.baseName(Path.At(Path.dot /../ "foo"))
    Some("foo")

    Path.baseName(Path.At(Path.dot /../ "foo" /../ ""))
    None

    Path.baseName(Path.At(Path.dot /../ "foo" / "bar" /../ ""))
    Some("foo")
 */
let baseName: t('kind) => option(string);

/**
 Appends one path to another. Preserves the relative/absoluteness of the first
 arguments.
 */
let append: (t('kind), string) => t('kind);
let join: (t('kind1), t('kind2)) => t('kind1);

/**
Tests for path equality
*/
let eq: (t('kind1), t('kind2)) => bool;

/**
Tests for path equality of two absolute paths.
*/
let absoluteEq: (t(absolute), t(absolute)) => bool;

/**
Tests for path equality of two absolute paths.
*/
let relativeEq: (t(relative), t(relative)) => bool;

/**
 Syntactic forms for utilities provided above. These are included in a separate
 module so that it can be opened safely without causing collisions with other
 identifiers in scope such as "root"/"home".

 Use like this:

     Path.At(Path.root / "foo" / "bar");
     Path.At(Path.dot /../ "bar");
 */
module At: {
  /**
   Performs `append` with infix syntax.
   */
  let (/): (t('kind), string) => t('kind);
  /**
   `dir /../ s` is equivalent to `append(dirName(dir), s)`
   */
  let (/../): (t('kind), string) => t('kind);
  /**
   `dir /../../ s` is equivalent to `append(dirName(dirName(dir)), s)`
   */
  let (/../../): (t('kind), string) => t('kind);
  /**
   `dir /../../../ s` is equivalent to
   `append(dirName(dirName(dirName(dir))), s)`
   */
  let (/../../../): (t('kind), string) => t('kind);
  /**
   `dir /../../../../ s` is equivalent to
   `append(dirName(dirName(dirName(dirName(dir)))), s)`
   */
  let (/../../../../): (t('kind), string) => t('kind);
  /**
   `dir /../../../../../ s` is equivalent to
   `append(dirName(dirName(dirName(dirName(dirName(dir))))), s)`
   */
  let (/../../../../../): (t('kind), string) => t('kind);
};
