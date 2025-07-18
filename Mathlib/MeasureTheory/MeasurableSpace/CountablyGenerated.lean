/-
Copyright (c) 2023 Felix Weilacher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Felix Weilacher, Yury Kudryashov, Rémy Degenne
-/
import Mathlib.MeasureTheory.MeasurableSpace.Embedding
import Mathlib.Data.Set.MemPartition
import Mathlib.Order.Filter.CountableSeparatingOn

/-!
# Countably generated measurable spaces

We say a measurable space is countably generated if it can be generated by a countable set of sets.

In such a space, we can also build a sequence of finer and finer finite measurable partitions of
the space such that the measurable space is generated by the union of all partitions.

## Main definitions

* `MeasurableSpace.CountablyGenerated`: class stating that a measurable space is countably
  generated.
* `MeasurableSpace.countableGeneratingSet`: a countable set of sets that generates the σ-algebra.
* `MeasurableSpace.countablePartition`: sequences of finer and finer partitions of
  a countably generated space, defined by taking the `memPartition` of an enumeration of the sets in
  `countableGeneratingSet`.
* `MeasurableSpace.SeparatesPoints` : class stating that a measurable space separates points.

## Main statements

* `MeasurableSpace.measurableEquiv_nat_bool_of_countablyGenerated`: if a measurable space is
  countably generated and separates points, it is measure equivalent to a subset of the Cantor Space
  `ℕ → Bool` (equipped with the product sigma algebra).
* `MeasurableSpace.measurable_injection_nat_bool_of_countablySeparated`: If a measurable space
  admits a countable sequence of measurable sets separating points,
  it admits a measurable injection into the Cantor space `ℕ → Bool`
  `ℕ → Bool` (equipped with the product sigma algebra).

The file also contains measurability results about `memPartition`, from which the properties of
`countablePartition` are deduced.

-/

open Set MeasureTheory

namespace MeasurableSpace

variable {α β : Type*}

/-- We say a measurable space is countably generated
if it can be generated by a countable set of sets. -/
class CountablyGenerated (α : Type*) [m : MeasurableSpace α] : Prop where
  isCountablyGenerated : ∃ b : Set (Set α), b.Countable ∧ m = generateFrom b

/-- A countable set of sets that generate the measurable space.
We insert `∅` to ensure it is nonempty. -/
def countableGeneratingSet (α : Type*) [MeasurableSpace α] [h : CountablyGenerated α] :
    Set (Set α) :=
  insert ∅ h.isCountablyGenerated.choose

lemma countable_countableGeneratingSet [MeasurableSpace α] [h : CountablyGenerated α] :
    Set.Countable (countableGeneratingSet α) :=
  Countable.insert _ h.isCountablyGenerated.choose_spec.1

lemma generateFrom_countableGeneratingSet [m : MeasurableSpace α] [h : CountablyGenerated α] :
    generateFrom (countableGeneratingSet α) = m :=
  (generateFrom_insert_empty _).trans <| h.isCountablyGenerated.choose_spec.2.symm

lemma empty_mem_countableGeneratingSet [MeasurableSpace α] [CountablyGenerated α] :
    ∅ ∈ countableGeneratingSet α := mem_insert _ _

lemma nonempty_countableGeneratingSet [MeasurableSpace α] [CountablyGenerated α] :
    Set.Nonempty (countableGeneratingSet α) :=
  ⟨∅, mem_insert _ _⟩

lemma measurableSet_countableGeneratingSet [MeasurableSpace α] [CountablyGenerated α]
    {s : Set α} (hs : s ∈ countableGeneratingSet α) :
    MeasurableSet s := by
  rw [← generateFrom_countableGeneratingSet (α := α)]
  exact measurableSet_generateFrom hs

/-- A countable sequence of sets generating the measurable space. -/
def natGeneratingSequence (α : Type*) [MeasurableSpace α] [CountablyGenerated α] : ℕ → (Set α) :=
  enumerateCountable (countable_countableGeneratingSet (α := α)) ∅

lemma generateFrom_natGeneratingSequence (α : Type*) [m : MeasurableSpace α]
    [CountablyGenerated α] : generateFrom (range (natGeneratingSequence _)) = m := by
  rw [natGeneratingSequence, range_enumerateCountable_of_mem _ empty_mem_countableGeneratingSet,
    generateFrom_countableGeneratingSet]

lemma measurableSet_natGeneratingSequence [MeasurableSpace α] [CountablyGenerated α] (n : ℕ) :
    MeasurableSet (natGeneratingSequence α n) :=
  measurableSet_countableGeneratingSet <| Set.enumerateCountable_mem _
    empty_mem_countableGeneratingSet n

theorem CountablyGenerated.comap [m : MeasurableSpace β] [h : CountablyGenerated β] (f : α → β) :
    @CountablyGenerated α (.comap f m) := by
  rcases h with ⟨⟨b, hbc, rfl⟩⟩
  rw [comap_generateFrom]
  letI := generateFrom (preimage f '' b)
  exact ⟨_, hbc.image _, rfl⟩

theorem CountablyGenerated.sup {m₁ m₂ : MeasurableSpace β} (h₁ : @CountablyGenerated β m₁)
    (h₂ : @CountablyGenerated β m₂) : @CountablyGenerated β (m₁ ⊔ m₂) := by
  rcases h₁ with ⟨⟨b₁, hb₁c, rfl⟩⟩
  rcases h₂ with ⟨⟨b₂, hb₂c, rfl⟩⟩
  exact @mk _ (_ ⊔ _) ⟨_, hb₁c.union hb₂c, generateFrom_sup_generateFrom⟩

/-- Any measurable space structure on a countable space is countably generated. -/
instance (priority := 100) [MeasurableSpace α] [Countable α] : CountablyGenerated α where
  isCountablyGenerated := by
    refine ⟨⋃ y, {measurableAtom y}, countable_iUnion (fun i ↦ countable_singleton _), ?_⟩
    refine le_antisymm ?_ (generateFrom_le (by simp [MeasurableSet.measurableAtom_of_countable]))
    intro s hs
    have : s = ⋃ y ∈ s, measurableAtom y := by
      apply Subset.antisymm
      · intro x hx
        simpa using ⟨x, hx, by simp⟩
      · simp only [iUnion_subset_iff]
        intro x hx
        exact measurableAtom_subset hs hx
    rw [this]
    apply MeasurableSet.biUnion (to_countable s) (fun x _hx ↦ ?_)
    apply measurableSet_generateFrom
    simp

instance [MeasurableSpace α] [CountablyGenerated α] {p : α → Prop} :
    CountablyGenerated { x // p x } := .comap _

instance [MeasurableSpace α] [CountablyGenerated α] [MeasurableSpace β] [CountablyGenerated β] :
    CountablyGenerated (α × β) :=
  .sup (.comap Prod.fst) (.comap Prod.snd)

section SeparatesPoints

/-- We say that a measurable space separates points if for any two distinct points,
there is a measurable set containing one but not the other. -/
class SeparatesPoints (α : Type*) [m : MeasurableSpace α] : Prop where
  separates : ∀ x y : α, (∀ s, MeasurableSet s → (x ∈ s → y ∈ s)) → x = y

theorem separatesPoints_def [MeasurableSpace α] [hs : SeparatesPoints α] {x y : α}
    (h : ∀ s, MeasurableSet s → (x ∈ s → y ∈ s)) : x = y := hs.separates _ _ h

theorem exists_measurableSet_of_ne [MeasurableSpace α] [SeparatesPoints α] {x y : α}
    (h : x ≠ y) : ∃ s, MeasurableSet s ∧ x ∈ s ∧ y ∉ s := by
  contrapose! h
  exact separatesPoints_def h

theorem separatesPoints_iff [MeasurableSpace α] : SeparatesPoints α ↔
    ∀ x y : α, (∀ s, MeasurableSet s → (x ∈ s ↔ y ∈ s)) → x = y :=
  ⟨fun h ↦ fun _ _ hxy ↦ h.separates _ _ fun _ hs xs ↦ (hxy _ hs).mp xs,
    fun h ↦ ⟨fun _ _ hxy ↦ h _ _ fun _ hs ↦
    ⟨fun xs ↦ hxy _ hs xs, not_imp_not.mp fun xs ↦ hxy _ hs.compl xs⟩⟩⟩

/-- If the measurable space generated by `S` separates points,
then this is witnessed by sets in `S`. -/
theorem separating_of_generateFrom (S : Set (Set α))
    [h : @SeparatesPoints α (generateFrom S)] :
    ∀ x y : α, (∀ s ∈ S, x ∈ s ↔ y ∈ s) → x = y := by
  letI := generateFrom S
  intros x y hxy
  rw [← forall_generateFrom_mem_iff_mem_iff] at hxy
  exact separatesPoints_def <| fun _ hs ↦ (hxy _ hs).mp

theorem SeparatesPoints.mono {m m' : MeasurableSpace α} [hsep : @SeparatesPoints _ m] (h : m ≤ m') :
    @SeparatesPoints _ m' := @SeparatesPoints.mk _ m' fun _ _ hxy ↦
    @SeparatesPoints.separates _ m hsep _ _ fun _ hs ↦ hxy _ (h _ hs)

/-- We say that a measurable space is countably separated if there is a
countable sequence of measurable sets separating points. -/
class CountablySeparated (α : Type*) [MeasurableSpace α] : Prop where
  countably_separated : HasCountableSeparatingOn α MeasurableSet univ

instance countablySeparated_of_hasCountableSeparatingOn [MeasurableSpace α]
    [h : HasCountableSeparatingOn α MeasurableSet univ] : CountablySeparated α := ⟨h⟩

instance hasCountableSeparatingOn_of_countablySeparated [MeasurableSpace α]
    [h : CountablySeparated α] : HasCountableSeparatingOn α MeasurableSet univ :=
  h.countably_separated

theorem countablySeparated_def [MeasurableSpace α] :
    CountablySeparated α ↔ HasCountableSeparatingOn α MeasurableSet univ :=
  ⟨fun h ↦ h.countably_separated, fun h ↦ ⟨h⟩⟩

theorem CountablySeparated.mono {m m' : MeasurableSpace α} [hsep : @CountablySeparated _ m]
    (h : m ≤ m') : @CountablySeparated _ m' := by
  simp_rw [countablySeparated_def] at *
  rcases hsep with ⟨S, Sct, Smeas, hS⟩
  use S, Sct, (fun s hs ↦ h _ <| Smeas _ hs), hS

theorem CountablySeparated.subtype_iff [MeasurableSpace α] {s : Set α} :
    CountablySeparated s ↔ HasCountableSeparatingOn α MeasurableSet s := by
  rw [countablySeparated_def]
  exact HasCountableSeparatingOn.subtype_iff

instance (priority := 100) Subtype.separatesPoints [MeasurableSpace α] [h : SeparatesPoints α]
    {s : Set α} : SeparatesPoints s :=
  ⟨fun _ _ hxy ↦ Subtype.val_injective <| h.1 _ _ fun _ ht ↦ hxy _ <| measurable_subtype_coe ht⟩

instance (priority := 100) Subtype.countablySeparated [MeasurableSpace α]
    [h : CountablySeparated α] {s : Set α} : CountablySeparated s := by
  rw [CountablySeparated.subtype_iff]
  exact h.countably_separated.mono (fun s ↦ id) <| subset_univ _

instance (priority := 100) separatesPoints_of_measurableSingletonClass [MeasurableSpace α]
    [MeasurableSingletonClass α] : SeparatesPoints α := by
  refine ⟨fun x y h ↦ ?_⟩
  specialize h _ (MeasurableSet.singleton x)
  simp_rw [mem_singleton_iff, forall_true_left] at h
  exact h.symm

instance (priority := 50) MeasurableSingletonClass.of_separatesPoints [MeasurableSpace α]
    [Countable α] [SeparatesPoints α] : MeasurableSingletonClass α where
  measurableSet_singleton x := by
    choose s hsm hxs hys using fun y (h : x ≠ y) ↦ exists_measurableSet_of_ne h
    convert MeasurableSet.iInter fun y ↦ .iInter fun h ↦ hsm y h
    ext y
    rcases eq_or_ne x y with rfl | h
    · simpa
    · simp only [mem_singleton_iff, h.symm, false_iff, mem_iInter, not_forall]
      exact ⟨y, h, hys y h⟩

instance hasCountableSeparatingOn_of_countablySeparated_subtype
    [MeasurableSpace α] {s : Set α} [h : CountablySeparated s] :
    HasCountableSeparatingOn _ MeasurableSet s := CountablySeparated.subtype_iff.mp h

instance countablySeparated_subtype_of_hasCountableSeparatingOn
    [MeasurableSpace α] {s : Set α} [h : HasCountableSeparatingOn _ MeasurableSet s] :
    CountablySeparated s := CountablySeparated.subtype_iff.mpr h

instance countablySeparated_of_separatesPoints [MeasurableSpace α]
    [h : CountablyGenerated α] [SeparatesPoints α] : CountablySeparated α := by
  rcases h with ⟨b, hbc, hb⟩
  refine ⟨⟨b, hbc, fun t ht ↦ hb.symm ▸ .basic t ht, ?_⟩⟩
  rw [hb] at ‹SeparatesPoints _›
  convert separating_of_generateFrom b
  simp

variable (α)

/-- If a measurable space admits a countable separating family of measurable sets,
there is a countably generated coarser space which still separates points. -/
theorem exists_countablyGenerated_le_of_countablySeparated [m : MeasurableSpace α]
    [h : CountablySeparated α] :
    ∃ m' : MeasurableSpace α, @CountablyGenerated _ m' ∧ @SeparatesPoints _ m' ∧ m' ≤ m := by
  rcases h with ⟨b, bct, hbm, hb⟩
  refine ⟨generateFrom b, ?_, ?_, generateFrom_le hbm⟩
  · use b
  rw [@separatesPoints_iff]
  exact fun x y hxy ↦ hb _ trivial _ trivial fun _ hs ↦ hxy _ <| measurableSet_generateFrom hs

open Function

open Classical in
/-- A map from a measurable space to the Cantor space `ℕ → Bool` induced by a countable
sequence of sets generating the measurable space. -/
noncomputable
def mapNatBool [MeasurableSpace α] [CountablyGenerated α] (x : α) (n : ℕ) :
    Bool := x ∈ natGeneratingSequence α n

theorem measurable_mapNatBool [MeasurableSpace α] [CountablyGenerated α] :
    Measurable (mapNatBool α) := by
  rw [measurable_pi_iff]
  refine fun n ↦ measurable_to_bool ?_
  simp only [preimage, mem_singleton_iff, mapNatBool,
    Bool.decide_iff, setOf_mem_eq]
  apply measurableSet_natGeneratingSequence

theorem injective_mapNatBool [MeasurableSpace α] [CountablyGenerated α]
    [SeparatesPoints α] : Injective (mapNatBool α) := by
  intro x y hxy
  rw [← generateFrom_natGeneratingSequence α] at *
  apply separating_of_generateFrom (range (natGeneratingSequence _))
  rintro - ⟨n, rfl⟩
  rw [← decide_eq_decide]
  exact congr_fun hxy n

/-- If a measurable space is countably generated and separates points, it is measure equivalent
to some subset of the Cantor space `ℕ → Bool` (equipped with the product sigma algebra).
Note: `s` need not be measurable, so this map need not be a `MeasurableEmbedding` to
the Cantor Space. -/
theorem measurableEquiv_nat_bool_of_countablyGenerated [MeasurableSpace α]
    [CountablyGenerated α] [SeparatesPoints α] :
    ∃ s : Set (ℕ → Bool), Nonempty (α ≃ᵐ s) := by
  use range (mapNatBool α), Equiv.ofInjective _ <|
    injective_mapNatBool _,
    Measurable.subtype_mk <| measurable_mapNatBool _
  simp_rw [← generateFrom_natGeneratingSequence α]
  apply measurable_generateFrom
  rintro _ ⟨n, rfl⟩
  rw [← Equiv.image_eq_preimage _ _]
  refine ⟨{y | y n}, by measurability, ?_⟩
  rw [← Equiv.preimage_eq_iff_eq_image]
  simp [mapNatBool]

/-- If a measurable space admits a countable sequence of measurable sets separating points,
it admits a measurable injection into the Cantor space `ℕ → Bool`
(equipped with the product sigma algebra). -/
theorem measurable_injection_nat_bool_of_countablySeparated [MeasurableSpace α]
    [CountablySeparated α] : ∃ f : α → ℕ → Bool, Measurable f ∧ Injective f := by
  rcases exists_countablyGenerated_le_of_countablySeparated α with ⟨m', _, _, m'le⟩
  refine ⟨mapNatBool α, ?_, injective_mapNatBool _⟩
  exact (measurable_mapNatBool _).mono m'le le_rfl

variable {α}

--TODO: Make this an instance
theorem measurableSingletonClass_of_countablySeparated
    [MeasurableSpace α] [CountablySeparated α] :
    MeasurableSingletonClass α := by
  rcases measurable_injection_nat_bool_of_countablySeparated α with ⟨f, fmeas, finj⟩
  refine ⟨fun x ↦ ?_⟩
  rw [← finj.preimage_image {x}, image_singleton]
  exact fmeas <| MeasurableSet.singleton _

end SeparatesPoints

section MeasurableMemPartition

lemma measurableSet_succ_memPartition (t : ℕ → Set α) (n : ℕ) {s : Set α}
    (hs : s ∈ memPartition t n) :
    MeasurableSet[generateFrom (memPartition t (n + 1))] s := by
  rw [← diff_union_inter s (t n)]
  refine MeasurableSet.union ?_ ?_ <;>
    · refine measurableSet_generateFrom ?_
      rw [memPartition_succ]
      exact ⟨s, hs, by simp⟩

lemma generateFrom_memPartition_le_succ (t : ℕ → Set α) (n : ℕ) :
    generateFrom (memPartition t n) ≤ generateFrom (memPartition t (n + 1)) :=
  generateFrom_le (fun _ hs ↦ measurableSet_succ_memPartition t n hs)

lemma measurableSet_generateFrom_memPartition_iff (t : ℕ → Set α) (n : ℕ) (s : Set α) :
    MeasurableSet[generateFrom (memPartition t n)] s
      ↔ ∃ S : Finset (Set α), ↑S ⊆ memPartition t n ∧ s = ⋃₀ S := by
  refine ⟨fun h ↦ ?_, fun ⟨S, hS_subset, hS_eq⟩ ↦ ?_⟩
  · induction s, h using generateFrom_induction with
    | hC u hu _ => exact ⟨{u}, by simp [hu], by simp⟩
    | empty => exact ⟨∅, by simp, by simp⟩
    | compl u _ hu =>
      obtain ⟨S, hS_subset, rfl⟩ := hu
      classical
      refine ⟨(memPartition t n).toFinset \ S, ?_, ?_⟩
      · simp only [Finset.coe_sdiff, coe_toFinset]
        exact diff_subset
      · simp only [Finset.coe_sdiff, coe_toFinset]
        refine (IsCompl.eq_compl ⟨?_, ?_⟩).symm
        · refine Set.disjoint_sUnion_right.mpr fun u huS => ?_
          refine Set.disjoint_sUnion_left.mpr fun v huV => ?_
          refine disjoint_memPartition t n (mem_of_mem_diff huV) (hS_subset huS) ?_
          exact ne_of_mem_of_not_mem huS (notMem_of_mem_diff huV) |>.symm
        · rw [codisjoint_iff]
          simp only [sup_eq_union, top_eq_univ]
          rw [← sUnion_memPartition t n, union_comm, ← sUnion_union, union_diff_cancel hS_subset]
    | iUnion f _ h =>
      choose S hS_subset hS_eq using h
      have : Fintype (⋃ n, (S n : Set (Set α))) := by
        refine (Finite.subset (finite_memPartition t n) ?_).fintype
        simp only [iUnion_subset_iff]
        exact hS_subset
      refine ⟨(⋃ n, (S n : Set (Set α))).toFinset, ?_, ?_⟩
      · simp only [coe_toFinset, iUnion_subset_iff]
        exact hS_subset
      · simp only [coe_toFinset, sUnion_iUnion, hS_eq]
  · rw [hS_eq, sUnion_eq_biUnion]
    refine MeasurableSet.biUnion ?_ (fun t ht ↦ ?_)
    · exact S.countable_toSet
    · exact measurableSet_generateFrom (hS_subset ht)

lemma measurableSet_generateFrom_memPartition (t : ℕ → Set α) (n : ℕ) :
    MeasurableSet[generateFrom (memPartition t (n + 1))] (t n) := by
  have : t n = ⋃ u ∈ memPartition t n, u ∩ t n := by
    simp_rw [← iUnion_inter, ← sUnion_eq_biUnion, sUnion_memPartition, univ_inter]
  rw [this]
  refine MeasurableSet.biUnion (finite_memPartition _ _).countable (fun v hv ↦ ?_)
  refine measurableSet_generateFrom ?_
  rw [memPartition_succ]
  exact ⟨v, hv, Or.inl rfl⟩

lemma generateFrom_iUnion_memPartition (t : ℕ → Set α) :
    generateFrom (⋃ n, memPartition t n) = generateFrom (range t) := by
  refine le_antisymm (generateFrom_le fun u hu ↦ ?_) (generateFrom_le fun u hu ↦ ?_)
  · simp only [mem_iUnion] at hu
    obtain ⟨n, hun⟩ := hu
    induction n generalizing u with
    | zero =>
      simp only [memPartition_zero, mem_singleton_iff] at hun
      rw [hun]
      exact MeasurableSet.univ
    | succ n ih =>
      simp only [memPartition_succ, mem_setOf_eq] at hun
      obtain ⟨v, hv, huv⟩ := hun
      rcases huv with rfl | rfl
      · exact (ih v hv).inter (measurableSet_generateFrom ⟨n, rfl⟩)
      · exact (ih v hv).diff (measurableSet_generateFrom ⟨n, rfl⟩)
  · simp only [mem_range] at hu
    obtain ⟨n, rfl⟩ := hu
    exact generateFrom_mono (subset_iUnion _ _) _ (measurableSet_generateFrom_memPartition t n)

lemma generateFrom_memPartition_le_range (t : ℕ → Set α) (n : ℕ) :
    generateFrom (memPartition t n) ≤ generateFrom (range t) := by
  conv_rhs => rw [← generateFrom_iUnion_memPartition t]
  exact generateFrom_mono (subset_iUnion _ _)

lemma generateFrom_iUnion_memPartition_le [m : MeasurableSpace α] {t : ℕ → Set α}
    (ht : ∀ n, MeasurableSet (t n)) :
    generateFrom (⋃ n, memPartition t n) ≤ m := by
  refine (generateFrom_iUnion_memPartition t).trans_le (generateFrom_le ?_)
  rintro s ⟨i, rfl⟩
  exact ht i

lemma generateFrom_memPartition_le [m : MeasurableSpace α] {t : ℕ → Set α}
    (ht : ∀ n, MeasurableSet (t n)) (n : ℕ) :
    generateFrom (memPartition t n) ≤ m :=
  (generateFrom_mono (subset_iUnion _ _)).trans (generateFrom_iUnion_memPartition_le ht)

lemma measurableSet_memPartition [MeasurableSpace α] {t : ℕ → Set α}
    (ht : ∀ n, MeasurableSet (t n)) (n : ℕ) {s : Set α} (hs : s ∈ memPartition t n) :
    MeasurableSet s :=
  generateFrom_memPartition_le ht n _ (measurableSet_generateFrom hs)

lemma measurableSet_memPartitionSet [MeasurableSpace α] {t : ℕ → Set α}
    (ht : ∀ n, MeasurableSet (t n)) (n : ℕ) (a : α) :
    MeasurableSet (memPartitionSet t n a) :=
  measurableSet_memPartition ht n (memPartitionSet_mem t n a)

end MeasurableMemPartition

variable [m : MeasurableSpace α] [h : CountablyGenerated α]

/-- For each `n : ℕ`, `countablePartition α n` is a partition of the space in at most
`2^n` sets. Each partition is finer than the preceding one. The measurable space generated by
the union of all those partitions is the measurable space on `α`. -/
def countablePartition (α : Type*) [MeasurableSpace α] [CountablyGenerated α] : ℕ → Set (Set α) :=
  memPartition (enumerateCountable countable_countableGeneratingSet ∅)

lemma measurableSet_enumerateCountable_countableGeneratingSet
    (α : Type*) [MeasurableSpace α] [CountablyGenerated α] (n : ℕ) :
    MeasurableSet (enumerateCountable (countable_countableGeneratingSet (α := α)) ∅ n) :=
  measurableSet_countableGeneratingSet
    (enumerateCountable_mem _ (empty_mem_countableGeneratingSet) n)

lemma finite_countablePartition (α : Type*) [MeasurableSpace α] [CountablyGenerated α] (n : ℕ) :
    Set.Finite (countablePartition α n) :=
  finite_memPartition _ n

instance instFinite_countablePartition (n : ℕ) : Finite (countablePartition α n) :=
  Set.finite_coe_iff.mp (finite_countablePartition _ _)

lemma disjoint_countablePartition {n : ℕ} {s t : Set α}
    (hs : s ∈ countablePartition α n) (ht : t ∈ countablePartition α n) (hst : s ≠ t) :
    Disjoint s t :=
  disjoint_memPartition _ n hs ht hst

lemma sUnion_countablePartition (α : Type*) [MeasurableSpace α] [CountablyGenerated α] (n : ℕ) :
    ⋃₀ countablePartition α n = univ :=
  sUnion_memPartition _ n

lemma measurableSet_generateFrom_countablePartition_iff (n : ℕ) (s : Set α) :
    MeasurableSet[generateFrom (countablePartition α n)] s
      ↔ ∃ S : Finset (Set α), ↑S ⊆ countablePartition α n ∧ s = ⋃₀ S :=
  measurableSet_generateFrom_memPartition_iff _ n s

lemma measurableSet_succ_countablePartition (n : ℕ) {s : Set α} (hs : s ∈ countablePartition α n) :
    MeasurableSet[generateFrom (countablePartition α (n + 1))] s :=
  measurableSet_succ_memPartition _ _ hs

lemma generateFrom_countablePartition_le_succ (α : Type*) [MeasurableSpace α] [CountablyGenerated α]
    (n : ℕ) :
    generateFrom (countablePartition α n) ≤ generateFrom (countablePartition α (n + 1)) :=
  generateFrom_memPartition_le_succ _ _

lemma generateFrom_iUnion_countablePartition (α : Type*) [m : MeasurableSpace α]
    [CountablyGenerated α] :
    generateFrom (⋃ n, countablePartition α n) = m := by
  rw [countablePartition, generateFrom_iUnion_memPartition,
    range_enumerateCountable_of_mem _ empty_mem_countableGeneratingSet,
    generateFrom_countableGeneratingSet]

lemma generateFrom_countablePartition_le (α : Type*) [m : MeasurableSpace α] [CountablyGenerated α]
    (n : ℕ) :
    generateFrom (countablePartition α n) ≤ m :=
  generateFrom_memPartition_le (measurableSet_enumerateCountable_countableGeneratingSet α) n

lemma measurableSet_countablePartition (n : ℕ) {s : Set α} (hs : s ∈ countablePartition α n) :
    MeasurableSet s :=
  generateFrom_countablePartition_le α n _ (measurableSet_generateFrom hs)

/-- The set in `countablePartition α n` to which `a : α` belongs. -/
def countablePartitionSet (n : ℕ) (a : α) : Set α :=
  memPartitionSet (enumerateCountable countable_countableGeneratingSet ∅) n a

lemma countablePartitionSet_mem (n : ℕ) (a : α) :
    countablePartitionSet n a ∈ countablePartition α n :=
  memPartitionSet_mem _ _ _

lemma mem_countablePartitionSet (n : ℕ) (a : α) : a ∈ countablePartitionSet n a :=
  mem_memPartitionSet _ _ _

lemma countablePartitionSet_eq_iff {n : ℕ} (a : α) {s : Set α} (hs : s ∈ countablePartition α n) :
    countablePartitionSet n a = s ↔ a ∈ s :=
  memPartitionSet_eq_iff _ hs

lemma countablePartitionSet_of_mem {n : ℕ} {a : α} {s : Set α} (hs : s ∈ countablePartition α n)
    (ha : a ∈ s) :
    countablePartitionSet n a = s :=
  memPartitionSet_of_mem hs ha

@[measurability]
lemma measurableSet_countablePartitionSet (n : ℕ) (a : α) :
    MeasurableSet (countablePartitionSet n a) :=
  measurableSet_countablePartition n (countablePartitionSet_mem n a)

section CountableOrCountablyGenerated

variable {α γ : Type*} [MeasurableSpace α] [MeasurableSpace β] [MeasurableSpace γ]

/-- A class registering that either `α` is countable or `β` is a countably generated
measurable space. -/
class CountableOrCountablyGenerated (α β : Type*) [MeasurableSpace α] [MeasurableSpace β] :
    Prop where
  countableOrCountablyGenerated : Countable α ∨ MeasurableSpace.CountablyGenerated β

instance instCountableOrCountablyGeneratedOfCountable [h1 : Countable α] :
    CountableOrCountablyGenerated α β := ⟨Or.inl h1⟩

instance instCountableOrCountablyGeneratedOfCountablyGenerated [h : CountablyGenerated β] :
    CountableOrCountablyGenerated α β := ⟨Or.inr h⟩

instance [hα : CountableOrCountablyGenerated α γ] [hβ : CountableOrCountablyGenerated β γ] :
    CountableOrCountablyGenerated (α × β) γ := by
  rcases hα with (hα | hα) <;> rcases hβ with (hβ | hβ) <;> infer_instance

lemma countableOrCountablyGenerated_left_of_prod_left_of_nonempty [Nonempty β]
    [h : CountableOrCountablyGenerated (α × β) γ] :
    CountableOrCountablyGenerated α γ := by
  rcases h.countableOrCountablyGenerated with (h | h)
  · have := countable_left_of_prod_of_nonempty h
    infer_instance
  · infer_instance

lemma countableOrCountablyGenerated_right_of_prod_left_of_nonempty [Nonempty α]
    [h : CountableOrCountablyGenerated (α × β) γ] :
    CountableOrCountablyGenerated β γ := by
  rcases h.countableOrCountablyGenerated with (h | h)
  · have := countable_right_of_prod_of_nonempty h
    infer_instance
  · infer_instance

lemma countableOrCountablyGenerated_prod_left_swap [h : CountableOrCountablyGenerated (α × β) γ] :
    CountableOrCountablyGenerated (β × α) γ := by
  rcases h with (h | h)
  · refine ⟨Or.inl countable_prod_swap⟩
  · exact ⟨Or.inr h⟩

end CountableOrCountablyGenerated

end MeasurableSpace
