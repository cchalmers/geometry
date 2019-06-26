{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies          #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Geometry.HasOrigin
-- Copyright   :  (c) 2011-2017 diagrams team (see LICENSE)
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  diagrams-discuss@googlegroups.com
--
-- Types which have an intrinsic notion of a \"local origin\",
-- /i.e./ things which are /not/ invariant under translation.
--
-----------------------------------------------------------------------------

module Geometry.HasOrigin
  ( HasOrigin(..)
  , moveOriginBy
  , moveTo
  , place
  ) where

import qualified Data.Map       as M
import qualified Data.Set       as S

import           Geometry.Space

import           Linear.Affine
import           Linear.Vector

import GHC.Stack

-- | Class of types which have an intrinsic notion of a \"local
--   origin\", i.e. things which are not invariant under translation,
--   and which allow the origin to be moved.
--
--   One might wonder why not just use 'Transformable' instead of
--   having a separate class for 'HasOrigin'; indeed, for types which
--   are instances of both we should have the identity
--
--   @
--   moveOriginTo (origin .^+ v) === translate (negated v)
--   @
--
--   The reason is that some things (e.g. vectors, 'Trail's) are
--   transformable but are translationally invariant, i.e. have no
--   origin.  Conversely, some types may have an origin and support
--   translation, but not support arbitrary affine transformations.
class HasOrigin t where

  -- | Move the local origin to another point.
  --
  --   Note that this function is in some sense dual to 'translate'
  --   (for types which are also 'Transformable'); moving the origin
  --   itself while leaving the object \"fixed\" is dual to fixing the
  --   origin and translating the object.
  moveOriginTo :: HasCallStack => Point (V t) (N t) -> t -> t

-- | Move the local origin by a relative vector.
moveOriginBy :: (InSpace v n t, HasCallStack, HasOrigin t) => v n -> t -> t
moveOriginBy = moveOriginTo . P
{-# INLINE moveOriginBy #-}

-- | Translate the object by the translation that sends the origin to
--   the given point. Note that this is dual to 'moveOriginTo', i.e. we
--   should have
--
--   @
--   moveTo (origin .+^ v) === moveOriginTo (origin .-^ v)
--   @
--
--   For types which are also 'Transformable', this is essentially the
--   same as 'translate', i.e.
--
--   @
--   moveTo (origin .+^ v) === translate v
--   @
moveTo :: (InSpace v n t, HasCallStack, HasOrigin t) => Point v n -> t -> t
moveTo = moveOriginBy . (origin .-.)
{-# INLINE moveTo #-}

-- | A flipped variant of 'moveTo', provided for convenience.  Useful
--   when writing a function which takes a point as an argument, such
--   as when using 'withName' and friends.
place :: (InSpace v n t, HasOrigin t) => t -> Point v n -> t
place = flip moveTo
{-# INLINE place #-}

instance (Additive v, Num n) => HasOrigin (Point v n) where
  moveOriginTo (P u) p = p .-^ u
  {-# INLINE moveOriginTo #-}

instance (HasOrigin t, HasOrigin s, SameSpace s t) => HasOrigin (s, t) where
  moveOriginTo p (x,y) = (moveOriginTo p x, moveOriginTo p y)
  {-# INLINE moveOriginTo #-}

instance HasOrigin t => HasOrigin [t] where
  moveOriginTo = map . moveOriginTo
  {-# INLINE moveOriginTo #-}

instance (HasOrigin t, Ord t) => HasOrigin (S.Set t) where
  moveOriginTo = S.map . moveOriginTo
  {-# INLINE moveOriginTo #-}

instance HasOrigin t => HasOrigin (M.Map k t) where
  moveOriginTo = M.map . moveOriginTo
  {-# INLINE moveOriginTo #-}

