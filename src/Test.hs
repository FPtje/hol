{- |
module: Main
description: Testing the higher order logic kernel
license: MIT

maintainer: Joe Leslie-Hurd <joe@gilith.com>
stability: provisional
portability: portable
-}
module Main
  ( main )
where

import Data.List (sort)
import Test.QuickCheck
import qualified Text.PrettyPrint as PP

import HOL.Name
import HOL.Print
import qualified HOL.Rule as Rule
import qualified HOL.Subst as Subst
import qualified HOL.Term as Term
import qualified HOL.TermAlpha as TermAlpha
import qualified HOL.Thm as Thm
import qualified HOL.Type as Type
import qualified HOL.TypeSubst as TypeSubst
import qualified HOL.TypeVar as TypeVar
import qualified HOL.Var as Var

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

checkWith :: Testable prop => Args -> (String,prop) -> IO ()
checkWith args (desc,prop) =
    do putStr (desc ++ " ")
       res <- quickCheckWithResult args prop
       case res of
         Failure {} -> error "Proposition failed"
         _ -> return ()

{- No parametrized tests yet
check :: Testable prop => (String,prop) -> IO ()
check = checkWith $ stdArgs {maxSuccess = 1000}
-}

assert :: (String,Bool) -> IO ()
assert = checkWith $ stdArgs {maxSuccess = 1}

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

compareType :: (String,Bool)
compareType = ("Comparing types",prop)
  where
    prop = sort [a,b,i] == [a,b,i]

    a = Type.alpha
    b = Type.bool
    i = Type.ind

composeTypeSubst :: (String,Bool)
composeTypeSubst = ("Composing type substitutions",prop)
  where
    prop = TypeSubst.compose sub1 sub2 == sub12 &&
           subst sub12 alpha == subst sub2 (subst sub1 alpha)

    sub1 = TypeSubst.singleton TypeVar.alpha ty1
    ty1 = Type.mkFun Type.bool alpha

    sub2 = TypeSubst.singleton TypeVar.alpha ty2
    ty2 = Type.mkFun alpha Type.bool

    sub12 = TypeSubst.singleton TypeVar.alpha ty12
    ty12 = Type.mkFun Type.bool ty2

    subst = TypeSubst.trySubst
    alpha = Type.alpha

--------------------------------------------------------------------------------
-- Terms
--------------------------------------------------------------------------------

compareTermAlpha :: (String,Bool)
compareTermAlpha = ("Comparing terms modulo alpha-equivalence",prop)
  where
    prop = --
           -- Comparing bound and free variables
           t1 < t2 && t2 < t3 && t3 < t4 &&
           a1 == a4 && a4 < a3 && a3 < a2 &&
           --
           -- Comparing bound variables by type
           t5 < t6 && t6 < t7 && t7 < t8 &&
           a7 == a8 && a8 < a5 && a5 < a6

    t1 = Term.mkAbs x (Term.mkVar x)
    t2 = Term.mkAbs x (Term.mkVar y)
    t3 = Term.mkAbs y (Term.mkVar x)
    t4 = Term.mkAbs y (Term.mkVar y)
    t5 = Term.mkAbs b t1
    t6 = Term.mkAbs i t1
    t7 = Term.mkAbs x t1
    t8 = Term.mkAbs y t1

    a1 = TermAlpha.mk t1
    a2 = TermAlpha.mk t2
    a3 = TermAlpha.mk t3
    a4 = TermAlpha.mk t4
    a5 = TermAlpha.mk t5
    a6 = TermAlpha.mk t6
    a7 = TermAlpha.mk t7
    a8 = TermAlpha.mk t8

    b = Var.mk (mkGlobal "b") Type.bool
    i = Var.mk (mkGlobal "i") Type.ind
    x = Var.mk (mkGlobal "x") Type.alpha
    y = Var.mk (mkGlobal "y") Type.alpha

substAvoidCapture :: (String,Bool)
substAvoidCapture = ("Term substitutions avoiding variable capture",prop)
  where
    prop = Subst.subst s1 t1 == Just t2 &&
           Subst.subst s2 t3 == Just t4 &&
           Subst.subst s2 t5 == Just t6

    s1 = Subst.singletonUnsafe p q'
    s2 = Subst.fromListUnsafe [(TypeVar.alpha,Type.bool)] []

    t1 = Term.mkAbs q (Term.mkEqUnsafe p' q')
    t2 = Term.mkAbs q0 (Term.mkEqUnsafe q' q0')
    t3 = Term.mkAbs qA (Term.mkEqUnsafe (Term.mkRefl q') (Term.mkRefl qA'))
    t4 = Term.mkAbs q0 (Term.mkEqUnsafe (Term.mkRefl q') (Term.mkRefl q0'))
    t5 = Term.mkAbs q (Term.mkEqUnsafe (Term.mkRefl q') (Term.mkRefl qA'))
    t6 = Term.mkAbs q0 (Term.mkEqUnsafe (Term.mkRefl q0') (Term.mkRefl q'))

    p' = Term.mkVar p
    q' = Term.mkVar q
    qA' = Term.mkVar qA
    q0' = Term.mkVar q0

    p = Var.mk (mkGlobal "p") Type.bool
    q = Var.mk (mkGlobal "q") Type.bool
    qA = Var.mk (mkGlobal "q") Type.alpha
    q0 = Var.mk (mkGlobal "q0") Type.bool

--------------------------------------------------------------------------------
-- Theorems
--------------------------------------------------------------------------------

inferenceRules :: (String,Bool)
inferenceRules = ("Rules of inference",prop)
  where
    prop = toString th1 == "|- (\\x. x) = \\x. x" &&
           toString th2 == "|- (\\a. abs (rep a)) = \\a. a" &&
           toString th3 == "|- (\\r. rep (abs r) = r) = \\r. (\\x. x) = r" &&
           toString th4 == "|- abs (rep a) = a" &&
           toString th5 == "|- (\\x. x) = r <=> rep (abs r) = r" &&
           toString th6 == "|- rep (abs r) = r <=> (\\x. x) = r"

    th1 = Thm.refl (Term.mkAbs x (Term.mkVar x))
    Just (_,_,_,th2,th3) = Thm.defineTypeOp unit absN rep [] th1
    Just (_,_,_,th4,th5) = Rule.defineTypeOpLegacy unit absN rep [] th1
    Just th6 = Rule.sym th5

    x = Var.mk (mkGlobal "x") Type.bool

    absN = mkGlobal "abs"
    rep = mkGlobal "rep"
    unit = mkGlobal "unit"

--------------------------------------------------------------------------------
-- Axioms
--------------------------------------------------------------------------------

printedAxioms :: String
printedAxioms =
    separator ++ "\n" ++
    "Axiom of Extensionality\n" ++
    "\n" ++
    toStringWith style Thm.axiomOfExtensionality ++ "\n" ++
    "\n" ++
    separator ++ "\n" ++
    "Axiom of Choice\n" ++
    "\n" ++
    toStringWith style Thm.axiomOfChoice ++ "\n" ++
    "\n" ++
    separator ++ "\n" ++
    "Axiom of Infinity\n" ++
    "\n" ++
    toStringWith style Thm.axiomOfInfinity ++ "\n" ++
    "\n" ++
    separator ++ "\n"
  where
    lineLength = 160
    separator = replicate lineLength '-'
    style = PP.style {PP.lineLength = lineLength, PP.ribbonsPerLine = 2.0}

printAxioms :: String -> (String,Bool)
printAxioms golden = ("Printing axioms",prop)
  where
    prop = printedAxioms == golden

{- Use this to update the axioms file
updatePrintedAxioms :: IO ()
updatePrintedAxioms = writeFile "doc/axioms.txt" printedAxioms
-}

--------------------------------------------------------------------------------
-- Main function
--------------------------------------------------------------------------------

main :: IO ()
main = do
    assert compareType
    assert composeTypeSubst
    assert compareTermAlpha
    assert substAvoidCapture
    assert inferenceRules
    do axioms <- readFile "doc/axioms.txt"
       assert $ printAxioms axioms
    return ()
