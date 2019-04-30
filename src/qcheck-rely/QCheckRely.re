module T = QCheck.Test;
module Rely = Rely;
open Rely.MatcherUtils;
open Rely.MatcherTypes;

let seed: ref(option(int)) = ref(None);

let seed_ =
  lazy {
    let s =
      try (int_of_string @@ Sys.getenv("QCHECK_SEED")) {
      | _ =>
        Random.self_init();
        Random.int(1000000000);
      };
    seed := Some(s);
    s;
  };

let default_rand = () =>
  /* random seed, for repeatability of tests */
  Random.State.make([|Lazy.force(seed_)|]);

let long_ =
  lazy (
    switch (Sys.getenv("QCHECK_LONG")) {
    | "1"
    | "true" => true
    | _ => false
    | exception Not_found => false
    }
  );

type qCheckRely = {
  make: (~long: bool=?, ~rand: Random.State.t=?, QCheck.Test.t) => unit,
  makeCell:
    'a.
    (~long: bool=?, ~rand: Random.State.t=?, QCheck.Test.cell('a)) => unit,

};

module Matchers = {
  type extension = {
    qCheckTest:
      (~long: bool=?, ~rand: Random.State.t=?, QCheck.Test.t) => unit,
    qCheckCell:
      'a.
      (~long: bool=?, ~rand: Random.State.t=?, QCheck.Test.cell('a)) => unit,

  };

  let seedToString = (seed: ref(option(int)), formatSeed) => {
    switch (seed^) {
    | None => None
    | Some(s) =>
      Some("qcheck random seed: " ++ formatSeed(string_of_int(s)))
    };
  };

  let pass = (() => "", true);

  let makeTestMatcher = (createMatcher, accessorPath) => {
    createMatcher(({formatReceived, indent, matcherHint, _}, actualThunk, _) => {
      let (QCheck.Test.Test(cell), rand: Random.State.t, long: bool) =
        actualThunk();

      switch (QCheck.Test.check_cell_exn(~long, ~rand, cell)) {
      | () => pass
      | exception (QCheck.Test.Test_fail(name, input)) =>
        let testNameFailureMessage = "QCheck test \"" ++ name ++ "\" failed";
        let inputMessage =
          "generated input: \n"
          ++ indent(formatReceived(String.concat("\n", input)));
        let messageParts =
          switch (seedToString(seed, formatReceived)) {
          | None => [testNameFailureMessage, "", inputMessage]
          | Some(s) => [testNameFailureMessage, "", inputMessage, s]
          };

        let message =
          String.concat(
            "\n",
            [
              matcherHint(
                ~expectType=accessorPath,
                ~matcherName="",
                ~isNot=false,
                ~expected="",
                (),
              )
              ++ "\n",
              ...messageParts,
            ],
          );
        ((() => message), false);
      | exception (QCheck.Test.Test_error(name, input, e, _)) =>
        let testNameFailureMessage =
          "QCheck test \""
          ++ name
          ++ "\" failed with exception "
          ++ Printexc.to_string(e);
        let inputMessage = "generated input: " ++ formatReceived(input);

        let messageParts =
          switch (seedToString(seed, formatReceived)) {
          | None => [testNameFailureMessage, "", inputMessage]
          | Some(s) => [testNameFailureMessage, "", inputMessage, s]
          };

        let message =
          String.concat(
            "\n",
            [
              matcherHint(
                ~expectType=accessorPath,
                ~matcherName="",
                ~isNot=false,
                ~expected="",
                (),
              )
              ++ "\n",
              ...messageParts,
            ],
          );
        ((() => message), false);
      };
    });
  };

  let makeCellMatcher = (createMatcher, accessorPath) => {
    createMatcher(({formatReceived, indent, matcherHint, _}, actualThunk, _) => {
      let (cell, rand: Random.State.t, long: bool) = actualThunk();

      switch (QCheck.Test.check_cell_exn(~long, ~rand, cell)) {
      | () => pass
      | exception (QCheck.Test.Test_fail(name, input)) =>
        let testNameFailureMessage = "QCheck test \"" ++ name ++ "\" failed";
        let inputMessage =
          "generated input: \n"
          ++ indent(formatReceived(String.concat("\n", input)));
        let messageParts =
          switch (seedToString(seed, formatReceived)) {
          | None => [testNameFailureMessage, "", inputMessage]
          | Some(s) => [testNameFailureMessage, "", inputMessage, s]
          };

        let message =
          String.concat(
            "\n",
            [
              matcherHint(
                ~expectType=accessorPath,
                ~matcherName="",
                ~isNot=false,
                ~expected="",
                (),
              )
              ++ "\n",
              ...messageParts,
            ],
          );
        ((() => message), false);
      | exception (QCheck.Test.Test_error(name, input, e, _)) =>
        let testNameFailureMessage =
          "QCheck test \""
          ++ name
          ++ "\" failed with exception "
          ++ Printexc.to_string(e);
        let inputMessage = "generated input: " ++ formatReceived(input);

        let messageParts =
          switch (seedToString(seed, formatReceived)) {
          | None => [testNameFailureMessage, "", inputMessage]
          | Some(s) => [testNameFailureMessage, "", inputMessage, s]
          };

        let message =
          String.concat(
            "\n",
            [
              matcherHint(
                ~expectType=accessorPath,
                ~matcherName="",
                ~isNot=false,
                ~expected="",
                (),
              )
              ++ "\n",
              ...messageParts,
            ],
          );
        ((() => message), false);
      };
    });
  };

  let matchers = ({createMatcher}) => {
    {
      qCheckTest: (~long=Lazy.force(long_), ~rand=default_rand(), t) =>
        makeTestMatcher(
          createMatcher,
          ".ext.qCheckTest",
          () => (t, rand, long),
          () => (),
        ),
      qCheckCell: (~long=Lazy.force(long_), ~rand=default_rand(), c) =>
        makeCellMatcher(
          createMatcher,
          ".ext.qCheckCell",
          () => (c, rand, long),
          () => (),
        ),
    };
  };
};

let toRely = (test: Rely.Test.testFn('a)) => {
  make: (~long=Lazy.force(long_), ~rand=default_rand(), t) => {
    let QCheck.Test.Test(cell) = t;
    let name = QCheck.Test.get_name(cell);
    test(
      name,
      _ => {
        let _ = QCheck.Test.check_cell_exn(~long, ~rand, cell);
        ();
      },
    );
    ();
  },
  makeCell: (~long=Lazy.force(long_), ~rand=default_rand(), cell) => {
    let name = QCheck.Test.get_name(cell);
    test(
      name,
      _ => {
        QCheck.Test.check_cell_exn(cell, ~long, ~rand);
        ();
      },
    );
    ();
  },
};
