/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Mario Carneiro

Ordinal arithmetic.

Ordinals are defined as equivalences of well-ordered sets by order isomorphism.
-/
import order.order_iso data.cardinal data.sum
noncomputable theory

open function cardinal
local attribute [instance] classical.prop_decidable

universes u v w
variables {α : Type*} {β : Type*} {γ : Type*}
  {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

structure initial_seg {α β : Type*} (r : α → α → Prop) (s : β → β → Prop) extends r ≼o s :=
(init : ∀ a b, s b (to_order_embedding a) → ∃ a', to_order_embedding a' = b)

local infix ` ≼i `:50 := initial_seg

namespace initial_seg

instance : has_coe (r ≼i s) (r ≼o s) := ⟨initial_seg.to_order_embedding⟩

@[simp] theorem coe_fn_mk (f : r ≼o s) (o) :
  (@initial_seg.mk _ _ r s f o : α → β) = f := rfl

@[simp] theorem coe_fn_to_order_embedding (f : r ≼i s) : (f.to_order_embedding : α → β) = f := rfl

@[simp] theorem coe_coe_fn (f : r ≼i s) : ((f : r ≼o s) : α → β) = f := rfl

theorem init' (f : r ≼i s) {a : α} {b : β} : s b (f a) → ∃ a', f a' = b :=
f.init _ _

theorem init_iff (f : r ≼i s) {a : α} {b : β} : s b (f a) ↔ ∃ a', f a' = b ∧ r a' a :=
⟨λ h, let ⟨a', e⟩ := f.init' h in ⟨a', e, (f : r ≼o s).ord'.2 (e.symm ▸ h)⟩,
 λ ⟨a', e, h⟩, e ▸ (f : r ≼o s).ord'.1 h⟩

def of_iso (f : r ≃o s) : r ≼i s :=
⟨f, λ a b h, ⟨f.symm b, order_iso.apply_inverse_apply f _⟩⟩

@[refl] protected def refl (r : α → α → Prop) : r ≼i r :=
⟨order_embedding.refl _, λ a b h, ⟨_, rfl⟩⟩

@[trans] protected def trans : r ≼i s → s ≼i t → r ≼i t
| ⟨f₁, o₁⟩ ⟨f₂, o₂⟩ := ⟨f₁.trans f₂, λ a c h, begin
  simp at h ⊢,
  rcases o₂ _ _ h with ⟨b, rfl⟩, have h := f₂.ord'.2 h,
  rcases o₁ _ _ h with ⟨a', rfl⟩, exact ⟨a', rfl⟩
end⟩

@[simp] theorem of_iso_apply (f : r ≃o s) (x : α) : of_iso f x = f x := rfl

@[simp] theorem refl_apply (x : α) : initial_seg.refl r x = x := rfl

@[simp] theorem trans_apply : ∀ (f : r ≼i s) (g : s ≼i t) (a : α), (f.trans g) a = g (f a)
| ⟨f₁, o₁⟩ ⟨f₂, o₂⟩ a := order_embedding.trans_apply _ _ _

def unique_of_extensional [is_extensional β s] :
  well_founded r → subsingleton (r ≼i s) | ⟨h⟩ :=
⟨λ f g, begin
  suffices : (f : α → β) = g, { cases f, cases g,
    congr, exact order_embedding.eq_of_to_fun_eq this },
  funext a, have := h a, induction this with a H IH,
  refine @is_extensional.ext _ s _ _ _ (λ x, ⟨λ h, _, λ h, _⟩),
  { rcases f.init_iff.1 h with ⟨y, rfl, h'⟩,
    rw IH _ h', exact (g : r ≼o s).ord'.1 h' },
  { rcases g.init_iff.1 h with ⟨y, rfl, h'⟩,
    rw ← IH _ h', exact (f : r ≼o s).ord'.1 h' }
end⟩

instance [is_well_order β s] : subsingleton (r ≼i s) :=
⟨λ a, @subsingleton.elim _ (unique_of_extensional
  (@order_embedding.well_founded _ _ r s a (is_well_order.wf s))) a⟩

protected theorem eq [is_well_order β s] (f g : r ≼i s) (a) : f a = g a :=
by rw subsingleton.elim f g

theorem antisymm.aux [is_well_order α r] (f : r ≼i s) (g : s ≼i r) : left_inverse g f
| x := begin
  have := ((is_well_order.wf r).apply x), induction this with x _ IH,
  refine @is_extensional.ext _ r _ _ _ (λ y, _),
  simp only [g.init_iff, f.init_iff],
  split; intro h,
  { rcases h with ⟨a, rfl, b, rfl, h⟩, rwa IH _ h },
  { exact ⟨f y, IH _ h, y, rfl, h⟩ }
end

def antisymm [is_well_order β s] (f : r ≼i s) (g : s ≼i r) : r ≃o s :=
by have := f.to_order_embedding.is_well_order; exact
⟨⟨f, g, antisymm.aux f g, antisymm.aux g f⟩, f.ord⟩

@[simp] theorem antisymm_to_fun [is_well_order β s]
  (f : r ≼i s) (g : s ≼i r) : (antisymm f g : α → β) = f := rfl

@[simp] theorem antisymm_symm [is_well_order α r] [is_well_order β s]
  (f : r ≼i s) (g : s ≼i r) : (antisymm f g).symm = antisymm g f :=
order_iso.eq_of_to_fun_eq $ by dunfold initial_seg.antisymm; simp

theorem eq_or_principal [is_well_order β s] (f : r ≼i s) : surjective f ∨ ∃ b, ∀ x, s x b ↔ ∃ y, f y = x :=
or_iff_not_imp_right.2 $ λ h b,
acc.rec_on ((is_well_order.wf s).apply b) $ λ x H IH,
not_forall_not.1 $ λ hn,
h ⟨x, λ y, ⟨(IH _), λ ⟨a, e⟩, by rw ← e; exact
  (trichotomous _ _).resolve_right
  (not_or (hn a) (λ hl, not_exists.2 hn (f.init' hl)))⟩⟩

def cod_restrict (p : set β) (f : r ≼i s) (H : ∀ a, f a ∈ p) : r ≼i subrel s p :=
⟨order_embedding.cod_restrict p f H, λ a ⟨b, m⟩ (h : s b (f a)),
  let ⟨a', e⟩ := f.init' h in ⟨a', by clear _let_match; subst e; refl⟩⟩

@[simp] theorem cod_restrict_apply (p) (f : r ≼i s) (H a) : cod_restrict p f H a = ⟨f a, H a⟩ := rfl

def le_add (r : α → α → Prop) (s : β → β → Prop) : r ≼i sum.lex r s :=
⟨⟨⟨sum.inl, λ _ _, sum.inl.inj⟩, λ a b, by simp⟩,
  λ a b, by cases b; simp; exact λ _, ⟨_, rfl⟩⟩

@[simp] theorem le_add_apply (r : α → α → Prop) (s : β → β → Prop)
  (a) : le_add r s a = sum.inl a := rfl

end initial_seg

structure principal_seg {α β : Type*} (r : α → α → Prop) (s : β → β → Prop) extends r ≼o s :=
(top : β)
(down : ∀ b, s b top ↔ ∃ a, to_order_embedding a = b)

local infix ` ≺i `:50 := principal_seg

namespace principal_seg

instance : has_coe (r ≺i s) (r ≼o s) := ⟨principal_seg.to_order_embedding⟩

@[simp] theorem coe_fn_mk (f : r ≼o s) (t o) :
  (@principal_seg.mk _ _ r s f t o : α → β) = f := rfl

@[simp] theorem coe_fn_to_order_embedding (f : r ≺i s) : (f.to_order_embedding : α → β) = f := rfl

@[simp] theorem coe_coe_fn (f : r ≺i s) : ((f : r ≼o s) : α → β) = f := rfl

theorem down' (f : r ≺i s) {b : β} : s b f.top ↔ ∃ a, f a = b :=
f.down _

theorem lt_top (f : r ≺i s) (a : α) : s (f a) f.top :=
f.down'.2 ⟨_, rfl⟩

theorem init [is_trans β s] (f : r ≺i s) {a : α} {b : β} (h : s b (f a)) : ∃ a', f a' = b :=
f.down'.1 $ trans h $ f.lt_top _

instance has_coe_initial_seg [is_trans β s] : has_coe (r ≺i s) (r ≼i s) :=
⟨λ f, ⟨f.to_order_embedding, λ a b, f.init⟩⟩

@[simp] theorem coe_coe_fn' [is_trans β s] (f : r ≺i s) : ((f : r ≼i s) : α → β) = f := rfl

theorem init_iff [is_trans β s] (f : r ≺i s) {a : α} {b : β} : s b (f a) ↔ ∃ a', f a' = b ∧ r a' a :=
initial_seg.init_iff f

theorem irrefl (r : α → α → Prop) [is_well_order α r] (f : r ≺i r) : false :=
begin
  have := f.lt_top f.top,
  rw [show f f.top = f.top, from
      initial_seg.eq ↑f (initial_seg.refl r) f.top] at this,
  exact irrefl _ this
end

def lt_le [is_trans β s] (f : r ≺i s) (g : s ≼i t) : r ≺i t :=
⟨@order_embedding.trans _ _ _ r s t f g, g f.top, λ a,
 by simp [g.init_iff, f.down', exists_and_distrib_left.symm,
          -exists_and_distrib_left, exists_swap]; refl⟩

@[simp] theorem lt_le_apply [is_trans β s] [is_trans γ t] (f : r ≺i s) (g : s ≼i t) (a : α) : (f.lt_le g) a = g (f a) :=
order_embedding.trans_apply _ _ _

@[simp] theorem lt_le_top [is_trans β s] [is_trans γ t] (f : r ≺i s) (g : s ≼i t) : (f.lt_le g).top = g f.top := rfl

@[trans] protected def trans [is_trans β s] [is_trans γ t] (f : r ≺i s) (g : s ≺i t) : r ≺i t :=
lt_le f g

@[simp] theorem trans_apply [is_trans β s] [is_trans γ t] (f : r ≺i s) (g : s ≺i t) (a : α) : (f.trans g) a = g (f a) :=
lt_le_apply _ _ _

@[simp] theorem trans_top [is_trans β s] [is_trans γ t] (f : r ≺i s) (g : s ≺i t) : (f.trans g).top = g f.top := rfl

def equiv_lt [is_trans β s] [is_trans γ t] (f : r ≃o s) (g : s ≺i t) : r ≺i t :=
⟨@order_embedding.trans _ _ _ r s t f g, g.top, λ c,
 by simp [g.down']; exact
 ⟨λ ⟨b, h⟩, ⟨f.symm b, by simp [h]⟩, λ ⟨a, h⟩, ⟨f a, h⟩⟩⟩

@[simp] theorem equiv_lt_apply [is_trans β s] [is_trans γ t] (f : r ≃o s) (g : s ≺i t) (a : α) : (equiv_lt f g) a = g (f a) :=
by delta equiv_lt; simp

@[simp] theorem equiv_lt_top [is_trans β s] [is_trans γ t] (f : r ≃o s) (g : s ≺i t) : (equiv_lt f g).top = g.top := rfl

instance [is_well_order β s] : subsingleton (r ≺i s) :=
⟨λ f g, begin
  have ef : (f : α → β) = g,
  { show ((f : r ≼i s) : α → β) = g,
    rw @subsingleton.elim _ _ (f : r ≼i s) g, refl },
  have et : f.top = g.top,
  { refine @is_extensional.ext _ s _ _ _ (λ x, _),
    simp [f.down, g.down, ef] },
  cases f, cases g, simp at ef et,
  congr; [apply order_embedding.eq_of_to_fun_eq, skip]; assumption
end⟩

theorem top_eq [is_well_order β s] [is_well_order γ t]
  (e : r ≃o s) (f : r ≺i t) (g : s ≺i t) : f.top = g.top :=
by rw subsingleton.elim f (principal_seg.equiv_lt e g); simp

def of_element {α : Type*} (r : α → α → Prop) [is_well_order α r] (a : α) :
  subrel r {b | r b a} ≺i r :=
⟨subrel.order_embedding _ _, a, λ b,
  ⟨λ h, ⟨⟨_, h⟩, rfl⟩, λ ⟨⟨_, h⟩, rfl⟩, h⟩⟩

@[simp] theorem of_element_apply {α : Type*} (r : α → α → Prop) [is_well_order α r] (a : α) (b) :
  of_element r a b = b.1 := rfl

@[simp] theorem of_element_top {α : Type*} (r : α → α → Prop) [is_well_order α r] (a : α) :
  (of_element r a).top = a := rfl

def cod_restrict
  (p : set β) (f : r ≺i s) (H : ∀ a, f a ∈ p) (H₂ : f.top ∈ p) : r ≺i subrel s p :=
⟨order_embedding.cod_restrict p f H, ⟨f.top, H₂⟩, λ ⟨b, h⟩,
  f.down'.trans $ exists_congr $ λ a,
  show (⟨f a, H a⟩ : p).1 = _ ↔ _, from ⟨subtype.eq, congr_arg _⟩⟩

@[simp] theorem cod_restrict_apply (p) (f : r ≺i s) (H H₂ a) : cod_restrict p f H H₂ a = ⟨f a, H a⟩ := rfl

@[simp] theorem cod_restrict_top (p) (f : r ≺i s) (H H₂) : (cod_restrict p f H H₂).top = ⟨f.top, H₂⟩ := rfl

end principal_seg

def initial_seg.lt_or_eq [is_well_order β s] (f : r ≼i s) : r ≺i s ⊕ r ≃o s :=
if h : surjective f then sum.inr (order_iso.of_surjective f h) else
have h' : _, from (initial_seg.eq_or_principal f).resolve_left h,
sum.inl ⟨f, classical.some h', classical.some_spec h'⟩

@[simp] theorem initial_seg.lt_or_eq_apply_left [is_well_order β s]
  (f : r ≼i s) {g} (h : f.lt_or_eq = sum.inl g) (a : α) : g a = f a :=
begin
  unfold initial_seg.lt_or_eq at h,
  by_cases sj : surjective f; simp [sj] at h,
  {cases h}, {subst h, refl}
end

@[simp] theorem initial_seg.lt_or_eq_apply_right [is_well_order β s]
  (f : r ≼i s) {g} (h : f.lt_or_eq = sum.inr g) (a : α) : g a = f a :=
begin
  unfold initial_seg.lt_or_eq at h,
  by_cases sj : surjective f; simp [sj] at h,
  {subst g, simp}, {cases h}
end

def initial_seg.le_lt [is_well_order β s] [is_trans γ t] (f : r ≼i s) (g : s ≺i t) : r ≺i t :=
match f.lt_or_eq with
| sum.inl f' := f'.trans g
| sum.inr f' := principal_seg.equiv_lt f' g
end

@[simp] theorem initial_seg.le_lt_apply [is_well_order β s] [is_trans γ t]
  (f : r ≼i s) (g : s ≺i t) (a : α) : (f.le_lt g) a = g (f a) :=
begin
  delta initial_seg.le_lt, cases h : f.lt_or_eq with f' f',
  { simp [f.lt_or_eq_apply_left h] },
  { simp [f.lt_or_eq_apply_right h] }
end

namespace order_embedding

def collapse_F [is_well_order β s] (f : r ≼o s) : Π a, {b // ¬ s (f a) b} :=
(order_embedding.well_founded f $ is_well_order.wf s).fix $ λ a IH, begin
  let S := {b | ∀ a h, s (IH a h).1 b},
  have : f a ∈ S, from λ a' h, ((trichotomous _ _)
    .resolve_left $ λ h', (IH a' h).2 $ trans (f.ord'.1 h) h')
    .resolve_left $ λ h', (IH a' h).2 $ h' ▸ f.ord'.1 h,
  exact ⟨(is_well_order.wf s).min S (set.ne_empty_of_mem this),
   (is_well_order.wf s).not_lt_min _ _ this⟩
end

theorem collapse_F.lt [is_well_order β s] (f : r ≼o s) {a : α}
   : ∀ {a'}, r a' a → s (collapse_F f a').1 (collapse_F f a).1 :=
show (collapse_F f a).1 ∈ {b | ∀ a' (h : r a' a), s (collapse_F f a').1 b}, begin
  unfold collapse_F, rw well_founded.fix_eq,
  apply well_founded.min_mem _ _
end

theorem collapse_F.not_lt [is_well_order β s] (f : r ≼o s) (a : α)
   {b} (h : ∀ a' (h : r a' a), s (collapse_F f a').1 b) : ¬ s b (collapse_F f a).1 :=
begin
  unfold collapse_F, rw well_founded.fix_eq,
  exact well_founded.not_lt_min _ _ _
    (show b ∈ {b | ∀ a' (h : r a' a), s (collapse_F f a').1 b}, from h)
end

def collapse [is_well_order β s] (f : r ≼o s) : r ≼i s :=
by have := order_embedding.is_well_order f; exact
⟨order_embedding.of_monotone
  (λ a, (collapse_F f a).1) (λ a b, collapse_F.lt f),
λ a b, by revert a; dsimp; exact
acc.rec_on ((is_well_order.wf s).apply b) (λ b H IH a h, begin
  let S := {a | ¬ s (collapse_F f a).1 b},
  have : S ≠ ∅ := set.ne_empty_of_mem (asymm h),
  existsi (is_well_order.wf r).min S this,
  refine ((@trichotomous _ s _ _ _).resolve_left _).resolve_right _,
  { exact (is_well_order.wf r).min_mem S this },
  { refine collapse_F.not_lt f _ (λ a' h', _),
    by_contradiction hn,
    exact (is_well_order.wf r).not_lt_min S this hn h' }
end)⟩

@[simp] theorem collapse_apply [is_well_order β s] (f : r ≼o s)
  (a) : collapse f a = (collapse_F f a).1 := rfl

end order_embedding

section well_ordering_thm
parameter {σ : Type*}

private def partial_wo := Σ p : set σ, {r // is_well_order p r}

private def partial_wo.le (x y : partial_wo) := ∃ f : x.2.1 ≼i y.2.1, ∀ x, (f x).1 = x.1

local infix ` ≤ `:50 := partial_wo.le

private def partial_wo.is_refl : is_refl _ (≤) :=
⟨λ a, ⟨initial_seg.refl _, λ x, rfl⟩⟩
local attribute [instance] partial_wo.is_refl

private def partial_wo.trans {a b c} : a ≤ b → b ≤ c → a ≤ c
| ⟨f, hf⟩ ⟨g, hg⟩ := ⟨f.trans g, λ a, by simp [hf, hg]⟩

private def sub_of_le {s t} : s ≤ t → s.1 ⊆ t.1
| ⟨f, hf⟩ x h := by have := (f ⟨x, h⟩).2; rwa [hf ⟨x, h⟩] at this

private def agree_of_le {s t} : s ≤ t → ∀ {a b} sa sb ta tb,
  s.2.1 ⟨a, sa⟩ ⟨b, sb⟩ ↔ t.2.1 ⟨a, ta⟩ ⟨b, tb⟩
| ⟨f, hf⟩ a b sa sb ta tb := by rw [f.to_order_embedding.ord',
  show f.to_order_embedding ⟨a, sa⟩ = ⟨a, ta⟩, from subtype.eq (hf ⟨a, sa⟩),
  show f.to_order_embedding ⟨b, sb⟩ = ⟨b, tb⟩, from subtype.eq (hf ⟨b, sb⟩)]

section
parameters {c : set partial_wo} (hc : @zorn.chain _ (≤) c)

private def U := ⋃₀ ((λ x:partial_wo, x.1) '' c)

private def R (x y : U) := ∃ a : partial_wo, a ∈ c ∧
  ∃ (hx : x.1 ∈ a.1) (hy : y.1 ∈ a.1), a.2.1 ⟨_, hx⟩ ⟨_, hy⟩

private lemma mem_U {a} : a ∈ U ↔ ∃ s : partial_wo, s ∈ c ∧ a ∈ s.1 :=
by unfold U; simp [-sigma.exists]

private lemma mem_U2 {a b} (au : a ∈ U) (bu : b ∈ U) :
  ∃ s : partial_wo, s ∈ c ∧ a ∈ s.1 ∧ b ∈ s.1 :=
let ⟨s, sc, as⟩ := mem_U.1 au, ⟨t, tc, bt⟩ := mem_U.1 bu,
    ⟨k, kc, ks, kt⟩ := hc.directed sc tc in
⟨k, kc, sub_of_le ks as, sub_of_le kt bt⟩

private lemma R_ex {s : partial_wo} (sc : s ∈ c)
  {a b : σ} (hb : b ∈ s.1) {au bu} :
  R ⟨a, au⟩ ⟨b, bu⟩ → ∃ ha, s.2.1 ⟨a, ha⟩ ⟨b, hb⟩
| ⟨t, tc, at', bt, h⟩ :=
  match hc.total_of_refl sc tc with
  | or.inr hr := ⟨sub_of_le hr at', (agree_of_le hr _ _ _ _).1 h⟩
  | or.inl hr@⟨f, hf⟩ := begin
      rw [← show (f ⟨b, hb⟩) = ⟨(subtype.mk b bu).val, bt⟩, from
        subtype.eq (hf _)] at h,
      rcases f.init_iff.1 h with ⟨a', e, h'⟩, cases a' with a' ha,
      have : a' = a,
      { have := congr_arg subtype.val e, rwa hf at this },
      subst a', exact ⟨_, h'⟩
    end
  end

private lemma R_iff {s : partial_wo} (sc : s ∈ c)
  {a b : σ} (ha hb) {au bu} :
  R ⟨a, au⟩ ⟨b, bu⟩ ↔ s.2.1 ⟨a, ha⟩ ⟨b, hb⟩ :=
⟨λ h, let ⟨_, h⟩ := R_ex sc hb h in h,
 λ h, ⟨s, sc, ha, hb, h⟩⟩

private def wo : is_well_order U R :=
⟨⟨⟨λ ⟨a, au⟩ ⟨b, bu⟩,
  let ⟨s, sc, ha, hb⟩ := mem_U2 au bu in
  by have := s.2.2; exact
  (@trichotomous _ s.2.1 _ ⟨a, ha⟩ ⟨b, hb⟩).imp
    (R_iff hc sc _ _).2
    (λ o, o.imp (λ h, by congr; injection h)
    (R_iff hc sc _ _).2)⟩,
⟨λ ⟨a, au⟩ h, let ⟨s, sc, ha⟩ := mem_U.1 au in
  by have := s.2.2; exact irrefl _ ((R_iff hc sc _ ha).1 h)⟩,
⟨λ ⟨a, au⟩ ⟨b, bu⟩ ⟨d, du⟩ ab bd,
  let ⟨s, sc, as, bs⟩ := mem_U2 au bu, ⟨t, tc, dt⟩ := mem_U.1 du,
      ⟨k, kc, ks, kt⟩ := hc.directed sc tc in begin
    simp only [R_iff hc kc, sub_of_le ks as, sub_of_le ks bs, sub_of_le kt dt] at ab bd ⊢,
    have := k.2.2, exact trans ab bd
  end⟩⟩,
⟨λ ⟨a, au⟩, let ⟨s, sc, ha⟩ := mem_U.1 au in
  suffices ∀ (a : s.1) au, acc R ⟨a.1, au⟩, from this ⟨a, ha⟩ au,
  λ a, acc.rec_on ((@is_well_order.wf _ _ s.2.2).apply a) $
  λ ⟨a, ha⟩ H IH au, ⟨_, λ ⟨b, hb⟩ h,
    let ⟨hb, h⟩ := R_ex sc ha h in IH ⟨b, hb⟩ h _⟩⟩⟩

theorem chain_ub : ∃ ub, ∀ a ∈ c, a ≤ ub :=
⟨⟨U, R, wo⟩, λ s sc, ⟨⟨⟨⟨
  λ a, ⟨a.1, mem_U.2 ⟨s, sc, a.2⟩⟩,
  λ a b h, by injection h with h; exact subtype.eq h⟩,
  λ a b, by cases a with a ha; cases b with b hb; exact
     (R_iff hc sc _ _).symm⟩,
  λ ⟨a, ha⟩ ⟨b, hb⟩ h,
    let ⟨bs, h'⟩ := R_ex sc ha h in ⟨⟨_, bs⟩, rfl⟩⟩,
  λ a, rfl⟩⟩

end

theorem well_ordering_thm : ∃ r, is_well_order σ r :=
let ⟨m, MM⟩ := zorn.zorn (λ c, chain_ub) (λ a b c, partial_wo.trans) in
suffices hf : ∀ a, a ∈ m.1, from
  let f : σ ≃ m.1 := ⟨λ a, ⟨a, hf a⟩, λ a, a.1, λ a, rfl, λ ⟨a, ha⟩, rfl⟩ in
  ⟨order.preimage f m.2.1,
    @order_embedding.is_well_order _ _ _ _ ↑(order_iso.preimage f m.2.1) m.2.2⟩,
λ a, classical.by_contradiction $ λ ha,
let f : (insert a m.1 : set σ) ≃ (m.1 ⊕ unit) :=
 ⟨λ x, if h : x.1 ∈ m.1 then sum.inl ⟨_, h⟩ else sum.inr ⟨⟩,
  λ x, sum.cases_on x (λ x, ⟨x.1, or.inr x.2⟩) (λ _, ⟨a, or.inl rfl⟩),
  λ x, match x with
    | ⟨_, or.inl rfl⟩ := by dsimp; rw [dif_neg ha]
    | ⟨x, or.inr h⟩ := by dsimp; rw [dif_pos h]
    end,
  λ x, by rcases x with ⟨x, h⟩ | ⟨⟨⟩⟩; dsimp;
    [rw [dif_pos h], rw [dif_neg ha]]⟩ in
let r' := sum.lex m.2.1 (@empty_relation unit) in
have r'wo : is_well_order _ r' := @sum.lex.is_well_order _ _ _ _ m.2.2 _,
let m' : partial_wo := ⟨insert a m.1, order.preimage f r',
  @order_embedding.is_well_order _ _ _ _ ↑(order_iso.preimage f r') r'wo⟩ in
let g : m.2.1 ≼i r' := ⟨⟨⟨sum.inl, λ a b, sum.inl.inj⟩,
  λ a b, by simp [r']⟩,
  λ a b h, begin
    rcases b with b | ⟨⟨⟩⟩; simp [r'] at h ⊢,
    { cases b, exact ⟨_, _, rfl⟩ },
    { contradiction }
  end⟩ in
ha (sub_of_le (MM m' ⟨g.trans
  (initial_seg.of_iso (order_iso.preimage f r').symm),
  λ x, rfl⟩) (or.inl rfl))

end well_ordering_thm

structure Well_order : Type (u+1) :=
(α : Type u)
(r : α → α → Prop)
(wo : is_well_order α r)

namespace Well_order

protected def equiv : Well_order → Well_order → Prop
| ⟨α, r, wo⟩ ⟨β, s, wo'⟩ := nonempty (r ≃o s)

protected def le : Well_order → Well_order → Prop
| ⟨α, r, wo⟩ ⟨β, s, wo'⟩ := nonempty (r ≼i s)

protected def lt : Well_order → Well_order → Prop
| ⟨α, r, wo⟩ ⟨β, s, wo'⟩ := nonempty (r ≺i s)

end Well_order

instance ordinal.is_equivalent : setoid Well_order :=
{ r     := Well_order.equiv,
  iseqv := ⟨λ⟨α, r, _⟩, ⟨order_iso.refl _⟩,
    λ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨e⟩, ⟨e.symm⟩,
    λ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨e₁⟩ ⟨e₂⟩, ⟨e₁.trans e₂⟩⟩ }

def ordinal : Type (u + 1) := quotient ordinal.is_equivalent

namespace ordinal

def type (r : α → α → Prop) [wo : is_well_order α r] : ordinal :=
⟦⟨α, r, wo⟩⟧

def typein (r : α → α → Prop) [wo : is_well_order α r] (a : α) : ordinal :=
type (subrel r {b | r b a})

theorem type_def (r : α → α → Prop) [wo : is_well_order α r] :
  @eq ordinal ⟦⟨α, r, wo⟩⟧ (type r) := rfl

@[simp] theorem type_def' (r : α → α → Prop) [is_well_order α r] {wo} :
  @eq ordinal ⟦⟨α, r, wo⟩⟧ (type r) := rfl

theorem type_eq {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] :
  type r = type s ↔ nonempty (r ≃o s) := quotient.eq

@[elab_as_eliminator] theorem induction_on {C : ordinal → Prop}
  (o : ordinal) (H : ∀ α r [is_well_order α r], C (type r)) : C o :=
quot.induction_on o $ λ ⟨α, r, wo⟩, @H α r wo

protected def le (a b : ordinal) : Prop :=
quotient.lift_on₂ a b Well_order.le $
λ ⟨α₁, r₁, o₁⟩ ⟨α₂, r₂, o₂⟩ ⟨β₁, s₁, p₁⟩ ⟨β₂, s₂, p₂⟩ ⟨f⟩ ⟨g⟩,
propext ⟨
  λ ⟨h⟩, ⟨(initial_seg.of_iso f.symm).trans $
    h.trans (initial_seg.of_iso g)⟩,
  λ ⟨h⟩, ⟨(initial_seg.of_iso f).trans $
    h.trans (initial_seg.of_iso g.symm)⟩⟩

instance : has_le ordinal := ⟨ordinal.le⟩

theorem type_le {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] :
  type r ≤ type s ↔ nonempty (r ≼i s) := iff.rfl

def lt (a b : ordinal) : Prop :=
quotient.lift_on₂ a b Well_order.lt $
λ ⟨α₁, r₁, o₁⟩ ⟨α₂, r₂, o₂⟩ ⟨β₁, s₁, p₁⟩ ⟨β₂, s₂, p₂⟩ ⟨f⟩ ⟨g⟩,
by exact propext ⟨
  λ ⟨h⟩, ⟨principal_seg.equiv_lt f.symm $
    h.lt_le (initial_seg.of_iso g)⟩,
  λ ⟨h⟩, ⟨principal_seg.equiv_lt f $
    h.lt_le (initial_seg.of_iso g.symm)⟩⟩
    
instance : has_lt ordinal := ⟨ordinal.lt⟩

@[simp] theorem type_lt {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] :
  type r < type s ↔ nonempty (r ≺i s) := iff.rfl

instance : partial_order ordinal :=
{ le := (≤),
  lt := (<),
  le_refl := quot.ind $ by exact λ ⟨α, r, wo⟩, ⟨initial_seg.refl _⟩,
  le_trans := λ a b c, quotient.induction_on₃ a b c $
    λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨f⟩ ⟨g⟩, ⟨f.trans g⟩,
  lt_iff_le_not_le := λ a b, quotient.induction_on₂ a b $
    λ ⟨α, r, _⟩ ⟨β, s, _⟩, by exact
      ⟨λ ⟨f⟩, ⟨⟨f⟩, λ ⟨g⟩, (f.lt_le g).irrefl _⟩,
      λ ⟨⟨f⟩, h⟩, sum.rec_on f.lt_or_eq (λ g, ⟨g⟩)
       (λ g, (h ⟨initial_seg.of_iso g.symm⟩).elim)⟩,
  le_antisymm := λ x b, show x ≤ b → b ≤ x → x = b, from
    quotient.induction_on₂ x b $ λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨h₁⟩ ⟨h₂⟩,
    by exact quot.sound ⟨initial_seg.antisymm h₁ h₂⟩ }

theorem typein_lt_type (r : α → α → Prop) [is_well_order α r]
  (a : α) : typein r a < type r :=
⟨principal_seg.of_element _ _⟩

@[simp] theorem typein_top {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] (f : r ≺i s) :
  typein s f.top = type r :=
eq.symm $ quot.sound ⟨order_iso.of_surjective
  (order_embedding.cod_restrict _ f f.lt_top)
  (λ ⟨a, h⟩, by rcases f.down'.1 h with ⟨b, rfl⟩; exact ⟨b, rfl⟩)⟩

@[simp] theorem typein_apply {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] (f : r ≼i s) (a : α) :
  ordinal.typein s (f a) = ordinal.typein r a :=
eq.symm $ quotient.sound ⟨order_iso.of_surjective
  (order_embedding.cod_restrict _
    ((subrel.order_embedding _ _).trans f)
    (λ ⟨x, h⟩, by simpa using f.to_order_embedding.ord'.1 h))
  (λ ⟨y, h⟩, by rcases f.init' h with ⟨a, rfl⟩;
    exact ⟨⟨a, f.to_order_embedding.ord'.2 h⟩, by simp⟩)⟩

@[simp] theorem typein_lt_typein (r : α → α → Prop) [is_well_order α r]
  {a b : α} : typein r a < typein r b ↔ r a b :=
⟨λ ⟨f⟩, begin
  have : f.top.1 = a,
  { let f' := principal_seg.of_element r a,
    let g' := f.trans (principal_seg.of_element r b),
    have : g'.top = f'.top, {rw subsingleton.elim f' g'},
    simpa [f', g'] },
  rw ← this, exact f.top.2
end, λ h, ⟨principal_seg.cod_restrict _
  (principal_seg.of_element r a)
  (λ x, @trans _ r _ _ _ _ x.2 h) h⟩⟩

theorem typein_surj (r : α → α → Prop) [is_well_order α r]
  {o} (h : o < type r) : ∃ a, typein r a = o :=
induction_on o (λ β s _ ⟨f⟩, ⟨f.top, by simp⟩) h

theorem typein_inj (r : α → α → Prop) [is_well_order α r]
  {a b} : typein r a = typein r b ↔ a = b :=
⟨λ h, ((@trichotomous _ r _ a b)
  .resolve_left (λ hn, ne_of_lt ((typein_lt_typein r).2 hn) h))
  .resolve_right (λ hn, ne_of_gt ((typein_lt_typein r).2 hn) h),
congr_arg _⟩

def enum (r : α → α → Prop) [is_well_order α r] (o) : o < type r → α :=
quot.rec_on o (λ ⟨β, s, _⟩ h, (classical.choice h).top) $
λ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨h⟩, begin
  refine funext (λ (H₂ : type t < type r), _),
  have H₁ : type s < type r, {rwa type_eq.2 ⟨h⟩},
  have : ∀ {o e} (H : o < type r), @@eq.rec
   (λ (o : ordinal), o < type r → α)
   (λ (h : type s < type r), (classical.choice h).top)
     e H = (classical.choice H₁).top, {intros, subst e},
  exact (this H₂).trans (principal_seg.top_eq h
    (classical.choice H₁) (classical.choice H₂))
end

theorem enum_type {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] (f : s ≺i r)
  {h : type s < type r} : enum r (type s) h = f.top :=
principal_seg.top_eq (order_iso.refl _) _ _

@[simp] theorem enum_typein (r : α → α → Prop) [is_well_order α r] (a : α)
  {h : typein r a < type r} : enum r (typein r a) h = a :=
by simp [typein, enum_type (principal_seg.of_element r a)]

@[simp] theorem typein_enum (r : α → α → Prop) [is_well_order α r]
  {o} (h : o < type r) : typein r (enum r o h) = o :=
let ⟨a, e⟩ := typein_surj r h in
by clear _let_match; subst e; simp

theorem enum_lt {α β} {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}
  [is_well_order α r] [is_well_order β s] [is_well_order γ t]
  (h₁ : type s < type r) (h₂ : type t < type r) :
  r (enum r (type s) h₁) (enum r 
  (type t) h₂) ↔ type s < type t :=
by rw [← typein_lt_typein r, typein_enum, typein_enum]

theorem wf : @well_founded ordinal (<) :=
⟨λ a, induction_on a $ λ α r wo, by exact
suffices ∀ a, acc (<) (typein r a), from
⟨_, λ o h, let ⟨a, e⟩ := typein_surj r h in e ▸ this a⟩,
λ a, acc.rec_on (wo.wf.apply a) $ λ x H IH, ⟨_, λ o h, begin
  rcases typein_surj r (lt_trans h (typein_lt_type r _)) with ⟨b, rfl⟩,
  exact IH _ ((typein_lt_typein r).1 h)
end⟩⟩

def card (o : ordinal) : cardinal :=
quot.lift_on o (λ ⟨α, r, _⟩, ⟦α⟧) $
λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨e⟩, quotient.sound ⟨e.to_equiv⟩

@[simp] theorem card_type (r : α → α → Prop) [is_well_order α r] :
  card (type r) = mk α := rfl

theorem card_le_card {o₁ o₂ : ordinal} : o₁ ≤ o₂ → card o₁ ≤ card o₂ :=
induction_on o₁ $ λ α r _, induction_on o₂ $ λ β s _ ⟨⟨⟨f, _⟩, _⟩⟩, ⟨f⟩

instance : has_zero ordinal :=
⟨⟦⟨ulift empty, empty_relation, by apply_instance⟩⟧⟩

theorem zero_eq_type_empty : 0 = @type empty empty_relation _ :=
quotient.sound ⟨⟨equiv.ulift, λ _ _, iff.rfl⟩⟩

@[simp] theorem card_zero : card 0 = 0 := rfl

theorem zero_le (o : ordinal) : 0 ≤ o :=
induction_on o $ λ α r _,
⟨⟨⟨embedding.of_not_nonempty $ λ ⟨⟨a⟩⟩, a.elim,
  λ ⟨a⟩, a.elim⟩, λ ⟨a⟩, a.elim⟩⟩

@[simp] theorem le_zero {o : ordinal} : o ≤ 0 ↔ o = 0 :=
by simp [le_antisymm_iff, zero_le]

theorem pos_iff_ne_zero {o : ordinal} : 0 < o ↔ o ≠ 0 :=
by simp [lt_iff_le_and_ne, eq_comm, zero_le]

instance : has_one ordinal :=
⟨⟦⟨ulift unit, empty_relation, by apply_instance⟩⟧⟩

theorem one_eq_type_unit : 1 = @type unit empty_relation _ :=
quotient.sound ⟨⟨equiv.ulift, λ _ _, iff.rfl⟩⟩

@[simp] theorem card_one : card 1 = 1 := rfl

instance : has_add ordinal.{u} :=
⟨λo₁ o₂, quotient.lift_on₂ o₁ o₂
  (λ ⟨α, r, wo⟩ ⟨β, s, wo'⟩, ⟦⟨α ⊕ β, sum.lex r s, by exact sum.lex.is_well_order⟩⟧
    : Well_order → Well_order → ordinal) $
λ ⟨α₁, r₁, o₁⟩ ⟨α₂, r₂, o₂⟩ ⟨β₁, s₁, p₁⟩ ⟨β₂, s₂, p₂⟩ ⟨f⟩ ⟨g⟩,
quot.sound ⟨order_iso.sum_lex_congr f g⟩⟩

@[simp] theorem type_add {α β : Type u} (r : α → α → Prop) (s : β → β → Prop)
  [is_well_order α r] [is_well_order β s] : type r + type s = type (sum.lex r s) := rfl

def succ (o : ordinal) : ordinal := o + 1

theorem lt_succ_self (o : ordinal.{u}) : o < succ o :=
induction_on o $ λ α r _,
⟨begin
  cases e : initial_seg.lt_or_eq
    (@initial_seg.le_add α (ulift.{u 0} unit) r empty_relation) with f f,
  { exact f },
  { have := (initial_seg.of_iso f).eq (initial_seg.le_add _ _) (f.symm (sum.inr ⟨()⟩)),
    simp at this, cases this }
end⟩

theorem succ_ne_zero (o : ordinal.{u}) : succ o ≠ 0 :=
ne_of_gt $ lt_of_le_of_lt (zero_le _) (lt_succ_self _)

theorem succ_le {a b : ordinal.{u}} : succ a ≤ b ↔ a < b :=
⟨lt_of_lt_of_le (lt_succ_self _),
induction_on a $ λ α r _, induction_on b $ λ β s _ ⟨⟨f, t, hf⟩⟩, begin
  refine ⟨⟨order_embedding.of_monotone (sum.rec _ _) (λ a b, _), λ a b, _⟩⟩,
  { exact f }, { exact λ _, t },
  { rcases a with a|⟨⟨⟨⟩⟩⟩; rcases b with b|⟨⟨⟨⟩⟩⟩,
    { simpa using f.ord'.1 },
    { simpa using (hf _).2 ⟨_, rfl⟩ },
    { simp },
    { simpa using false.elim } },
  { rcases a with a|⟨⟨⟨⟩⟩⟩,
    { intro h, have := principal_seg.init ⟨f, t, hf⟩ h,
      simp at this, simp [this] },
    { simp [(hf _).symm] {contextual := tt} } }
end⟩

@[simp] theorem card_add (o₁ o₂ : ordinal) : card (o₁ + o₂) = card o₁ + card o₂ :=
induction_on o₁ $ λ α r _, induction_on o₂ $ λ β s _, rfl

@[simp] theorem card_succ (o : ordinal) : card (succ o) = card o + 1 :=
by simp [succ]

@[simp] theorem card_nat (n : ℕ) : card.{u} n = n :=
by induction n; simp *

theorem succ_nat_cast (n : ℕ) : (succ n : ordinal) = n.succ := rfl

instance : add_monoid ordinal.{u} :=
{ add       := (+),
  zero      := 0,
  zero_add  := λ o, induction_on o $ λ α r _, eq.symm $ quot.sound
    ⟨⟨(equiv.symm $ (equiv.ulift.sum_congr (equiv.refl _)).trans (equiv.empty_sum _)),
    λ a b, show r a b ↔ sum.lex _ _ (sum.inr a) (sum.inr b), by simp⟩⟩,
  add_zero  := λ o, induction_on o $ λ α r _, eq.symm $ quot.sound
    ⟨⟨(equiv.symm $ ((equiv.refl _).sum_congr equiv.ulift).trans (equiv.sum_empty _)),
    λ a b, show r a b ↔ sum.lex _ _ (sum.inl a) (sum.inl b), by simp⟩⟩,
  add_assoc := λ o₁ o₂ o₃, quotient.induction_on₃ o₁ o₂ o₃ $
    λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩, quot.sound
    ⟨⟨equiv.sum_assoc _ _ _, λ a b,
    by rcases a with ⟨a|a⟩|a; rcases b with ⟨b|b⟩|b; simp⟩⟩ }

theorem add_succ (o₁ o₂ : ordinal) : o₁ + succ o₂ = succ (o₁ + o₂) :=
(add_assoc _ _ _).symm

@[simp] theorem succ_zero : succ 0 = 1 := zero_add _

theorem add_le_add_left {o₁ o₂ : ordinal} : o₁ ≤ o₂ → ∀ o₃, o₃ + o₁ ≤ o₃ + o₂ :=
induction_on o₁ $ λ α₁ r₁ _, induction_on o₂ $ λ α₂ r₂ _ ⟨⟨⟨f, fo⟩, fi⟩⟩ o₃,
induction_on o₃ $ λ β s _,
⟨⟨⟨(embedding.refl _).sum_congr f,
  λ a b, by cases a with a a; cases b with b b; simp [fo]⟩,
  λ a b, begin
    cases b with b b, { simp [(⟨_, rfl⟩ : ∃ a, a=b)] },
    cases a with a a; simp, exact fi _ _,
  end⟩⟩

theorem le_add_right (o₁ o₂ : ordinal) : o₁ ≤ o₁ + o₂ :=
by simpa using add_le_add_left (zero_le o₂) o₁

theorem add_le_add_iff_left (o₁) {o₂ o₃ : ordinal} : o₁ + o₂ ≤ o₁ + o₃ ↔ o₂ ≤ o₃ :=
⟨induction_on o₁ $ λ α r _, induction_on o₂ $ λ β₁ s₁ _, induction_on o₃ $ λ β₂ s₂ _ ⟨f⟩, ⟨
  have fl : ∀ a, f (sum.inl a) = sum.inl a := λ a,
    by simpa using initial_seg.eq ((initial_seg.le_add r s₁).trans f) (initial_seg.le_add r s₂) a,
  have ∀ b, {b' // f (sum.inr b) = sum.inr b'}, begin
    intro b, cases e : f (sum.inr b),
    { rw ← fl at e, have := f.inj e, contradiction },
    { exact ⟨_, rfl⟩ }
  end,
  let g (b) := (this b).1 in
  have fr : ∀ b, f (sum.inr b) = sum.inr (g b), from λ b, (this b).2,
  ⟨⟨⟨g, λ x y h, by injection f.inj
    (by rw [fr, fr, h] : f (sum.inr x) = f (sum.inr y))⟩,
    λ a b, by simpa [fr] using @order_embedding.ord _ _ _ _
      f.to_order_embedding (sum.inr a) (sum.inr b)⟩,
    λ a b, begin
      have nex : ¬ ∃ (a : α), f (sum.inl a) = sum.inr b :=
        λ ⟨a, e⟩, by rw [fl] at e; injection e,
      simpa [fr, nex] using f.init (sum.inr a) (sum.inr b),
    end⟩⟩,
λ h, add_le_add_left h _⟩

def lift (o : ordinal.{u}) : ordinal.{max u v} :=
quotient.lift_on o (λ ⟨α, r, wo⟩,
  @type _ _ (@order_embedding.is_well_order _ _ (@equiv.ulift.{u v} α ⁻¹'o r) r
    (order_iso.preimage equiv.ulift.{u v} r) wo)) $
λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨f⟩,
quot.sound ⟨(order_iso.preimage equiv.ulift r).trans $
  f.trans (order_iso.preimage equiv.ulift s).symm⟩

theorem lift_umax : lift.{u (max u v)} = lift.{u v} :=
funext $ λ a, induction_on a $ λ α r _,
quotient.sound ⟨(order_iso.preimage equiv.ulift r).trans (order_iso.preimage equiv.ulift r).symm⟩

@[simp] theorem lift_id (a : ordinal) : lift a = a :=
induction_on a $ λ α r _,
quotient.sound ⟨order_iso.preimage equiv.ulift r⟩

@[simp] theorem lift_lift (a : ordinal) : lift.{(max u v) w} (lift.{u v} a) = lift.{u (max v w)} a :=
induction_on a $ λ α r _,
quotient.sound ⟨(order_iso.preimage equiv.ulift _).trans $
  (order_iso.preimage equiv.ulift _).trans (order_iso.preimage equiv.ulift _).symm⟩

theorem lift_type_le {α : Type u} {β : Type v} {r s} [is_well_order α r] [is_well_order β s] :
  lift.{u (max v w)} (type r) ≤ lift.{v (max u w)} (type s) ↔ nonempty (r ≼i s) :=
⟨λ ⟨f⟩, ⟨(initial_seg.of_iso (order_iso.preimage equiv.ulift r).symm).trans $
    f.trans (initial_seg.of_iso (order_iso.preimage equiv.ulift s))⟩,
 λ ⟨f⟩, ⟨(initial_seg.of_iso (order_iso.preimage equiv.ulift r)).trans $
    f.trans (initial_seg.of_iso (order_iso.preimage equiv.ulift s).symm)⟩⟩

theorem lift_type_eq {α : Type u} {β : Type v} {r s} [is_well_order α r] [is_well_order β s] :
  lift.{u (max v w)} (type r) = lift.{v (max u w)} (type s) ↔ nonempty (r ≃o s) :=
quotient.eq.trans
⟨λ ⟨f⟩, ⟨(order_iso.preimage equiv.ulift r).symm.trans $
    f.trans (order_iso.preimage equiv.ulift s)⟩,
 λ ⟨f⟩, ⟨(order_iso.preimage equiv.ulift r).trans $
    f.trans (order_iso.preimage equiv.ulift s).symm⟩⟩

theorem lift_type_lt {α : Type u} {β : Type v} {r s} [is_well_order α r] [is_well_order β s] :
  lift.{u (max v w)} (type r) < lift.{v (max u w)} (type s) ↔ nonempty (r ≺i s) :=
by have := @order_embedding.is_well_order _ _ (@equiv.ulift.{u (max v w)} α ⁻¹'o r)
     r (order_iso.preimage equiv.ulift.{u (max v w)} r) _;
   have := @order_embedding.is_well_order _ _ (@equiv.ulift.{v (max u w)} β ⁻¹'o s)
     s (order_iso.preimage equiv.ulift.{v (max u w)} s) _; exact
⟨λ ⟨f⟩, ⟨(f.equiv_lt (order_iso.preimage equiv.ulift r).symm).lt_le
    (initial_seg.of_iso (order_iso.preimage equiv.ulift s))⟩,
 λ ⟨f⟩, ⟨(f.equiv_lt (order_iso.preimage equiv.ulift r)).lt_le
    (initial_seg.of_iso (order_iso.preimage equiv.ulift s).symm)⟩⟩

@[simp] theorem lift_le {a b : ordinal} : lift.{u v} a ≤ lift b ↔ a ≤ b :=
induction_on a $ λ α r _, induction_on b $ λ β s _,
by rw ← lift_umax; exact lift_type_le

@[simp] theorem lift_inj {a b : ordinal} : lift a = lift b ↔ a = b :=
by simp [le_antisymm_iff]

@[simp] theorem lift_lt {a b : ordinal} : lift a < lift b ↔ a < b :=
by simp [lt_iff_le_not_le, -not_le]

@[simp] theorem lift_zero : lift 0 = 0 :=
quotient.sound ⟨(order_iso.preimage equiv.ulift _).trans
 ⟨equiv.ulift.trans equiv.ulift.symm, λ a b, iff.rfl⟩⟩

theorem zero_eq_lift_type_empty : 0 = lift.{0 u} (@type empty empty_relation _) :=
by rw [← zero_eq_type_empty, lift_zero]

@[simp] theorem lift_one : lift 1 = 1 :=
quotient.sound ⟨(order_iso.preimage equiv.ulift _).trans
 ⟨equiv.ulift.trans equiv.ulift.symm, λ a b, iff.rfl⟩⟩

theorem one_eq_lift_type_unit : 1 = lift.{0 u} (@type unit empty_relation _) :=
by rw [← one_eq_type_unit, lift_one]

@[simp] theorem lift_add (a b) : lift (a + b) = lift a + lift b :=
quotient.induction_on₂ a b $ λ ⟨α, r, _⟩ ⟨β, s, _⟩, 
quotient.sound ⟨(order_iso.preimage equiv.ulift _).trans
 (order_iso.sum_lex_congr (order_iso.preimage equiv.ulift _)
   (order_iso.preimage equiv.ulift _)).symm⟩

@[simp] theorem lift_succ (a) : lift (succ a) = succ (lift a) :=
by unfold succ; simp

@[simp] theorem lift_card (a) : (card a).lift = card (lift a) :=
induction_on a $ λ α r _, rfl

theorem lift_down' {a : cardinal.{u}} {b : ordinal.{max u v}}
  (h : card b ≤ a.lift) : ∃ a', lift a' = b :=
let ⟨c, e⟩ := cardinal.lift_down h in
quotient.induction_on c (λ α, induction_on b $ λ β s _ e', begin
  dsimp at e',
  rw [← cardinal.lift_id.{(max u v) u} (mk β),
      ← cardinal.lift_umax.{u v}, lift_mk_eq.{u (max u v) (max u v)}] at e',
  cases e' with f,
  have g := order_iso.preimage f s,
  have := g.to_order_embedding.is_well_order,
  have := lift_type_eq.{u (max u v) (max u v)}.2 ⟨g⟩,
  rw [lift_id.{(max u v) (max u v)}, lift_umax.{u v}] at this,
  exact ⟨_, this⟩
end) e

theorem lift_down {a : ordinal.{u}} {b : ordinal.{max u v}}
  (h : b ≤ lift a) : ∃ a', lift a' = b :=
@lift_down' (card a) _ (by rw lift_card; exact card_le_card h)

theorem le_lift_iff {a : ordinal.{u}} {b : ordinal.{max u v}} :
  b ≤ lift a ↔ ∃ a', lift a' = b ∧ a' ≤ a :=
⟨λ h, let ⟨a', e⟩ := lift_down h in ⟨a', e, lift_le.1 $ e.symm ▸ h⟩,
 λ ⟨a', e, h⟩, e ▸ lift_le.2 h⟩

theorem lt_lift_iff {a : ordinal.{u}} {b : ordinal.{max u v}} :
  b < lift a ↔ ∃ a', lift a' = b ∧ a' < a :=
⟨λ h, let ⟨a', e⟩ := lift_down (le_of_lt h) in
      ⟨a', e, lift_lt.1 $ e.symm ▸ h⟩,
 λ ⟨a', e, h⟩, e ▸ lift_lt.2 h⟩

def omega : ordinal.{u} := lift $ @type ℕ (<) _

theorem card_omega : card omega = cardinal.omega := rfl

@[simp] theorem lift_omega : lift omega = omega := lift_lift _

theorem type_le' {α β} {r : α → α → Prop} {s : β → β → Prop}
  [is_well_order α r] [is_well_order β s] : type r ≤ type s ↔ nonempty (r ≼o s) :=
⟨λ ⟨f⟩, ⟨f⟩, λ ⟨f⟩, ⟨f.collapse⟩⟩

theorem add_le_add_right {a b : ordinal} : a ≤ b → ∀ c, a + c ≤ b + c :=
induction_on a $ λ α₁ r₁ _, induction_on b $ λ α₂ r₂ _ ⟨⟨⟨f, fo⟩, fi⟩⟩ c,
induction_on c $ λ β s _, by exact type_le'.2
⟨⟨embedding.sum_congr f (embedding.refl _),
  λ a b, by cases a with a a; cases b with b b; simp [fo]⟩⟩

theorem le_add_left (a b : ordinal) : a ≤ b + a :=
by simpa using add_le_add_right (zero_le b) a

theorem le_total (a b : ordinal) : a ≤ b ∨ b ≤ a :=
match lt_or_eq_of_le (le_add_left b a), lt_or_eq_of_le (le_add_right a b) with
| or.inr h, _ := by rw h; exact or.inl (le_add_right _ _)
| _, or.inr h := by rw h; exact or.inr (le_add_left _ _)
| or.inl h₁, or.inl h₂ := induction_on a (λ α₁ r₁ _,
  induction_on b $ λ α₂ r₂ _ ⟨f⟩ ⟨g⟩, begin
    rw [← typein_top f, ← typein_top g, le_iff_lt_or_eq,
        le_iff_lt_or_eq, typein_lt_typein, typein_lt_typein],
    rcases trichotomous_of (sum.lex r₁ r₂) g.top f.top with h|h|h; simp [h],
  end) h₁ h₂
end

instance : linear_order ordinal :=
{ le_total := le_total, ..ordinal.partial_order }

theorem lt_succ {a b : ordinal} : a < succ b ↔ a ≤ b :=
by rw [← not_le, succ_le, not_lt]

theorem add_lt_add_iff_left (a) {b c : ordinal} : a + b < a + c ↔ b < c :=
by rw [← not_le, ← not_le, add_le_add_iff_left]

theorem lt_of_add_lt_add_right {a b c : ordinal} : a + b < c + b → a < c :=
le_imp_le_iff_lt_imp_lt.1 (λ h, add_le_add_right h _)

@[simp] theorem succ_lt_succ {a b : ordinal} : succ a < succ b ↔ a < b :=
by rw [lt_succ, succ_le]

@[simp] theorem succ_le_succ {a b : ordinal} : succ a ≤ succ b ↔ a ≤ b :=
le_iff_le_iff_lt_iff_lt.2 succ_lt_succ

theorem succ_inj {a b : ordinal} : succ a = succ b ↔ a = b :=
by simp [le_antisymm_iff]

@[simp] theorem card_eq_zero {o} : card o = 0 ↔ o = 0 :=
⟨induction_on o $ λ α r _ h, begin
  refine le_antisymm (le_of_not_lt $
    λ hn, ne_zero_iff_nonempty.2 _ h) (zero_le _),
  rw [← succ_le, succ_zero] at hn, cases hn with f,
  exact ⟨f ⟨()⟩⟩
end, λ e, by simp [e]⟩

@[simp] theorem type_ne_zero_iff_nonempty [is_well_order α r] : type r ≠ 0 ↔ nonempty α :=
(not_congr (@card_eq_zero (type r))).symm.trans ne_zero_iff_nonempty

@[simp] theorem type_eq_zero_iff_empty [is_well_order α r] : type r = 0 ↔ ¬ nonempty α :=
(not_iff_comm.1 type_ne_zero_iff_nonempty).symm

instance : zero_ne_one_class ordinal.{u} :=
{ zero := 0, one := 1, zero_ne_one :=
  ne.symm $ type_ne_zero_iff_nonempty.2 ⟨⟨()⟩⟩ }

def pred (o : ordinal.{u}) : ordinal.{u} :=
if h : ∃ a, o = succ a then classical.some h else o

@[simp] theorem pred_succ (o) : pred (succ o) = o :=
by have h : ∃ a, succ o = succ a := ⟨_, rfl⟩;
   simpa [pred, h] using (succ_inj.1 $ classical.some_spec h).symm

theorem pred_le_self (o) : pred o ≤ o :=
if h : ∃ a, o = succ a then let ⟨a, e⟩ := h in
by rw [e, pred_succ]; exact le_of_lt (lt_succ_self _)
else by simp [pred, h]

theorem pred_eq_iff_not_succ {o} : pred o = o ↔ ¬ ∃ a, o = succ a :=
⟨λ e ⟨a, e'⟩, by rw [e', pred_succ] at e; exact ne_of_lt (lt_succ_self _) e,
 λ h, dif_neg h⟩

theorem pred_lt_iff_is_succ {o} : pred o < o ↔ ∃ a, o = succ a :=
iff.trans (by simp [le_antisymm_iff, pred_le_self])
  (iff_not_comm.1 pred_eq_iff_not_succ).symm

theorem succ_pred_iff_is_succ {o} : succ (pred o) = o ↔ ∃ a, o = succ a :=
⟨λ e, ⟨_, e.symm⟩, λ ⟨a, e⟩, by simp [e]⟩

theorem succ_lt_of_not_succ {o} (h : ¬ ∃ a, o = succ a) {b} : succ b < o ↔ b < o :=
⟨lt_trans (lt_succ_self _), λ l,
  lt_of_le_of_ne (succ_le.2 l) (λ e, h ⟨_, e.symm⟩)⟩

theorem lt_pred {a b} : a < pred b ↔ succ a < b :=
if h : ∃ a, b = succ a then let ⟨c, e⟩ := h in
by rw [e, pred_succ, succ_lt_succ]
else by simpa [pred, h, succ_lt_of_not_succ]

theorem pred_le {a b} : pred a ≤ b ↔ a ≤ succ b :=
le_iff_le_iff_lt_iff_lt.2 lt_pred

@[simp] theorem lift_is_succ {o} : (∃ a, lift o = succ a) ↔ (∃ a, o = succ a) :=
⟨λ ⟨a, h⟩,
  let ⟨b, e⟩ := lift_down $ show a ≤ lift o, from le_of_lt $
    h.symm ▸ lt_succ_self _ in
  ⟨b, lift_inj.1 $ by rw [h, ← e, lift_succ]⟩,
 λ ⟨a, h⟩, ⟨lift a, by simp [h]⟩⟩

@[simp] theorem lift_pred (o) : lift (pred o) = pred (lift o) :=
if h : ∃ a, o = succ a then
by cases h with a e; simp [e]
else by rw [pred_eq_iff_not_succ.2 h,
            pred_eq_iff_not_succ.2 (mt lift_is_succ.1 h)]

def is_limit (o : ordinal) : Prop := o ≠ 0 ∧ ∀ a < o, succ a < o

theorem not_succ_is_limit (o) : ¬ is_limit (succ o)
| ⟨_, h⟩ := lt_irrefl _ (h _ (lt_succ_self _))

theorem not_succ_of_is_limit {o} (h : is_limit o) : ¬ ∃ a, o = succ a
| ⟨a, e⟩ := not_succ_is_limit a (e ▸ h)

theorem succ_lt_of_is_limit {o} (h : is_limit o) {a} : succ a < o ↔ a < o :=
⟨lt_trans (lt_succ_self _), h.2 _⟩

theorem le_succ_of_is_limit {o} (h : is_limit o) {a} : o ≤ succ a ↔ o ≤ a :=
le_iff_le_iff_lt_iff_lt.2 $ succ_lt_of_is_limit h

theorem limit_le {o} (h : is_limit o) {a} : o ≤ a ↔ ∀ x < o, x ≤ a :=
⟨λ h x l, le_trans (le_of_lt l) h,
 λ H, (le_succ_of_is_limit h).1 $ le_of_not_lt $ λ hn,
  not_lt_of_le (H _ hn) (lt_succ_self _)⟩

@[simp] theorem lift_is_limit (o) : is_limit (lift o) ↔ is_limit o :=
and_congr (not_congr $ by simpa using @lift_inj o 0)
⟨λ H a h, lift_lt.1 $ by simpa using H _ (lift_lt.2 h),
 λ H a h, let ⟨a', e⟩ := lift_down (le_of_lt h) in
   by rw [← e, ← lift_succ, lift_lt];
      rw [← e, lift_lt] at h; exact H a' h⟩

theorem pos_of_is_limit {o : ordinal} (h : is_limit o) : 0 < o :=
lt_of_le_of_ne (zero_le _) h.1.symm

theorem zero_or_succ_or_limit (o : ordinal) :
  o = 0 ∨ (∃ a, o = succ a) ∨ is_limit o :=
if o0 : o = 0 then or.inl o0 else
if h : ∃ a, o = succ a then or.inr (or.inl h) else
or.inr $ or.inr ⟨o0, λ a, (succ_lt_of_not_succ h).2⟩

theorem add_le_of_limit {a b c : ordinal.{u}}
  (h : is_limit b) : a + b ≤ c ↔ ∀ b' < b, a + b' ≤ c :=
⟨λ h b' l, le_trans (add_le_add_left (le_of_lt l) _) h,
λ H, le_of_not_lt $
induction_on a (λ α r _, induction_on b $ λ β s _ h H l, begin
  suffices : ∀ x : β, sum.lex r s (sum.inr x) (enum _ _ l),
  { cases enum _ _ l with x x,
    { simpa using this (enum s 0 (pos_of_is_limit h)) },
    { exact irrefl _ (this _) } },
  intros x,
  rw [← typein_lt_typein (sum.lex r s), typein_enum],
  have := H _ (h.2 _ (typein_lt_type s x)),
  rw [add_succ, succ_le] at this,
  refine lt_of_le_of_lt (type_le'.2
    ⟨order_embedding.of_monotone (λ a, _) (λ a b, _)⟩) this,
  { rcases a with ⟨a | b, h⟩,
    { exact sum.inl a },
    { exact sum.inr ⟨b, by simpa using h⟩ } },
  { rcases a with ⟨a | a, h₁⟩; rcases b with ⟨b | b, h₂⟩; simp }
end) h H⟩

theorem add_is_limit (a) {b} (h : is_limit b) : is_limit (a + b) :=
⟨ne_of_gt $ lt_of_lt_of_le (pos_of_is_limit h) (le_add_left _ _),
λ c, le_imp_le_iff_lt_imp_lt.1 $ λ h',
(add_le_of_limit h).2 $ λ d h, begin
  refine succ_le_succ.1 (le_trans _ h'),
  rwa [succ_le, add_lt_add_iff_left],
end⟩

instance : is_well_order ordinal (<) := ⟨by apply_instance, wf⟩

@[elab_as_eliminator] def limit_rec_on {C : ordinal → Sort*}
  (o : ordinal) (H₁ : C 0) (H₂ : ∀ o, C o → C (succ o))
  (H₃ : ∀ o, is_limit o → (∀ o' < o, C o') → C o) : C o :=
wf.fix (λ o IH,
  if o0 : o = 0 then by rw o0; exact H₁ else
  if h : ∃ a, o = succ a then
    by rw ← succ_pred_iff_is_succ.2 h; exact
    H₂ _ (IH _ $ pred_lt_iff_is_succ.2 h)
  else H₃ _ ⟨o0, λ a, (succ_lt_of_not_succ h).2⟩ IH) o

@[simp] theorem limit_rec_on_zero {C} (H₁ H₂ H₃) : @limit_rec_on C 0 H₁ H₂ H₃ = H₁ :=
by rw [limit_rec_on, well_founded.fix_eq]; simp; refl

set_option pp.proofs true
@[simp] theorem limit_rec_on_succ {C} (o H₁ H₂ H₃) :
  @limit_rec_on C (succ o) H₁ H₂ H₃ = H₂ o (@limit_rec_on C o H₁ H₂ H₃) :=
begin
  have h : ∃ a, succ o = succ a := ⟨_, rfl⟩,
  rw [limit_rec_on, well_founded.fix_eq,
      dif_neg (succ_ne_zero o), dif_pos h],
  generalize : limit_rec_on._proof_2 (succ o) h = h₂,
  generalize : limit_rec_on._proof_3 (succ o) h = h₃,
  revert h₂ h₃, generalize e : pred (succ o) = o', intros,
  rw pred_succ at e, subst o', refl
end

@[simp] theorem limit_rec_on_limit {C} (o H₁ H₂ H₃ h) :
  @limit_rec_on C o H₁ H₂ H₃ = H₃ o h (λ x h, @limit_rec_on C x H₁ H₂ H₃) :=
by rw [limit_rec_on, well_founded.fix_eq,
       dif_neg h.1, dif_neg (not_succ_of_is_limit h)]; refl

def typein.principal_seg {α : Type u} (r : α → α → Prop) [is_well_order α r] :
  @principal_seg α ordinal.{u} r (<) :=
⟨order_embedding.of_monotone (typein r)
  (λ a b, (typein_lt_typein r).2), type r, λ b,
    ⟨λ h, ⟨enum r _ h, typein_enum r h⟩,
    λ ⟨a, e⟩, e ▸ typein_lt_type _ _⟩⟩

@[simp] theorem typein.principal_seg_coe (r : α → α → Prop) [is_well_order α r] :
  (typein.principal_seg r : α → ordinal) = typein r := rfl

def min {ι} (I : nonempty ι) (f : ι → ordinal) : ordinal :=
wf.min (set.range f) (let ⟨i⟩ := I in set.ne_empty_of_mem (set.mem_range_self i))

theorem min_eq {ι} (I) (f : ι → ordinal) : ∃ i, min I f = f i :=
let ⟨i, e⟩ := wf.min_mem (set.range f) _ in ⟨i, e.symm⟩

theorem min_le {ι I} (f : ι → ordinal) (i) : min I f ≤ f i :=
le_of_not_gt $ wf.not_lt_min (set.range f) _ (set.mem_range_self i)

theorem le_min {ι I} {f : ι → ordinal} {a} : a ≤ min I f ↔ ∀ i, a ≤ f i :=
⟨λ h i, le_trans h (min_le _ _),
 λ h, let ⟨i, e⟩ := min_eq I f in e.symm ▸ h i⟩

@[simp] theorem lift_min {ι} (I) (f : ι → ordinal) : lift (min I f) = min I (lift ∘ f) :=
le_antisymm (le_min.2 $ λ a, lift_le.2 $ min_le _ a) $
let ⟨i, e⟩ := min_eq I (lift ∘ f) in
by rw e; exact lift_le.2 (le_min.2 $ λ j, lift_le.1 $
by have := min_le (lift ∘ f) j; rwa e at this)

def lift.initial_seg : @initial_seg ordinal.{u} ordinal.{max u v} (<) (<) :=
⟨⟨⟨lift.{u v}, λ a b, lift_inj.1⟩, λ a b, lift_lt.symm⟩,
  λ a b h, lift_down (le_of_lt h)⟩

@[simp] theorem lift.initial_seg_coe : (lift.initial_seg : ordinal → ordinal) = lift := rfl

def lift.principal_seg : @principal_seg ordinal.{u} ordinal.{max (u+1) v} (<) (<) :=
⟨↑lift.initial_seg.{u (max (u+1) v)}, lift.{(u+1) v} (@type ordinal.{u} (<) _), begin
  refine λ b, induction_on b _, intros β s _,
  rw ← lift_umax, split; intro h,
  { rw ← lift_id.{(max (u+1) v) (max (u+1) v)} (type s) at h ⊢,
    cases lift_type_lt.1 h with f, cases f with f a hf,
    existsi a, revert hf,
    apply induction_on a, intros α r _ hf,
    refine lift_type_eq.{u (max (u+1) v) (max (u+1) v)}.2
      ⟨(order_iso.of_surjective (order_embedding.of_monotone _ _) _).symm⟩,
    { exact λ b, enum r (f b) ((hf _).2 ⟨_, rfl⟩) },
    { refine λ a b h, (typein_lt_typein r).1 _,
      rw [typein_enum, typein_enum],
      exact f.ord'.1 h },
    { intro a', cases (hf _).1 (typein_lt_type _ a') with b e,
      existsi b, simp, simp [e] } },
  { cases h with a e, rw [← e],
    apply induction_on a, intros α r _,
    exact lift_type_lt.{u (u+1) (max (u+1) v)}.2
      ⟨typein.principal_seg r⟩ }
end⟩

@[simp] theorem lift.principal_seg_coe :
  (lift.principal_seg.{u v} : ordinal → ordinal) = lift.{u (max (u+1) v)} := rfl

@[simp] theorem lift.principal_seg_top :
  lift.principal_seg.{u v}.top = lift.{(u+1) v} (@type ordinal.{u} (<) _) := rfl

theorem lift.principal_seg_top' :
  lift.principal_seg.{u (u+1)}.top = @type ordinal.{u} (<) _ :=
by simp [lift_id.{(u+1) (u+1)}]

def sub (a b : ordinal.{u}) : ordinal.{u} :=
@min.{(u+2) u} {o // a ≤ b+o} ⟨⟨a, le_add_left _ _⟩⟩ subtype.val

instance : has_sub ordinal := ⟨sub⟩

theorem le_add_sub (a b : ordinal) : a ≤ b + (a - b) :=
let ⟨⟨o, l⟩, e⟩ := @min_eq {o // a ≤ b+o} _ _ in
by rwa ← (show a - b = o, from e) at l

theorem sub_le {a b c : ordinal} : a - b ≤ c ↔ a ≤ b + c :=
⟨λ h, le_trans (le_add_sub a b) (add_le_add_left h _),
 λ h, @min_le {o // a ≤ b+o} _ _ ⟨_, h⟩⟩

theorem lt_sub {a b c : ordinal} : a < b - c ↔ c + a < b :=
le_iff_le_iff_lt_iff_lt.1 sub_le

theorem add_sub_cancel (a b : ordinal) : a + b - a = b :=
le_antisymm (sub_le.2 $ le_refl _)
  ((add_le_add_iff_left a).1 $ le_add_sub _ _)

theorem sub_le_self (a b : ordinal) : a - b ≤ a :=
sub_le.2 $ le_add_left _ _

theorem add_sub_cancel_of_le {a b : ordinal} (h : b ≤ a) : b + (a - b) = a :=
le_antisymm begin
  rcases zero_or_succ_or_limit (a-b) with e|⟨c,e⟩|l,
  { simp [e, h] },
  { rw [e, add_succ, succ_le, ← lt_sub, e], apply lt_succ_self },
  { exact (add_le_of_limit l).2 (λ c l, le_of_lt (lt_sub.1 l)) }
end (le_add_sub _ _)

@[simp] theorem sub_zero (a : ordinal) : a - 0 = a :=
by simpa using add_sub_cancel 0 a

@[simp] theorem zero_sub (a : ordinal) : 0 - a = 0 :=
by rw ← le_zero; apply sub_le_self

@[simp] theorem sub_self (a : ordinal) : a - a = 0 :=
by simpa using add_sub_cancel a 0

instance : has_mul ordinal.{u} :=
⟨λo₁ o₂, quotient.lift_on₂ o₁ o₂
  (λ ⟨α, r, wo⟩ ⟨β, s, wo'⟩, ⟦⟨β × α, prod.lex s r, by exact prod.lex.is_well_order⟩⟧
    : Well_order → Well_order → ordinal) $
λ ⟨α₁, r₁, o₁⟩ ⟨α₂, r₂, o₂⟩ ⟨β₁, s₁, p₁⟩ ⟨β₂, s₂, p₂⟩ ⟨f⟩ ⟨g⟩,
quot.sound ⟨order_iso.prod_lex_congr g f⟩⟩

@[simp] theorem type_mul {α β : Type u} (r : α → α → Prop) (s : β → β → Prop)
  [is_well_order α r] [is_well_order β s] : type r * type s = type (prod.lex s r) := rfl

@[simp] theorem lift_mul (a b) : lift (a * b) = lift a * lift b :=
quotient.induction_on₂ a b $ λ ⟨α, r, _⟩ ⟨β, s, _⟩, 
quotient.sound ⟨(order_iso.preimage equiv.ulift _).trans
 (order_iso.prod_lex_congr (order_iso.preimage equiv.ulift _)
   (order_iso.preimage equiv.ulift _)).symm⟩

@[simp] theorem card_mul (a b) : card (a * b) = card a * card b :=
quotient.induction_on₂ a b $ λ ⟨α, r, _⟩ ⟨β, s, _⟩,
mul_comm (mk β) (mk α)

@[simp] theorem mul_zero (a : ordinal) : a * 0 = 0 :=
induction_on a $ λ α _ _, by exact
type_eq_zero_iff_empty.2 (λ ⟨⟨⟨e⟩, _⟩⟩, e.elim)

@[simp] theorem zero_mul (a : ordinal) : 0 * a = 0 :=
induction_on a $ λ α _ _, by exact
type_eq_zero_iff_empty.2 (λ ⟨⟨_, ⟨e⟩⟩⟩, e.elim)

@[simp] theorem mul_one (a : ordinal) : a * 1 = a :=
induction_on a $ λ α r _, by exact
quotient.sound
  ⟨⟨(equiv.ulift.prod_congr (equiv.refl _)).trans (equiv.unit_prod _),
    λ a b, by rcases a with ⟨⟨⟨⟩⟩, a⟩; rcases b with ⟨⟨⟨⟩⟩, b⟩;
              simp [prod.lex_def, empty_relation]⟩⟩

@[simp] theorem one_mul (a : ordinal) : 1 * a = a :=
induction_on a $ λ α r _, by exact
quotient.sound
  ⟨⟨((equiv.refl _).prod_congr equiv.ulift).trans (equiv.prod_unit _),
    λ a b, by rcases a with ⟨a, ⟨⟨⟩⟩⟩; rcases b with ⟨b, ⟨⟨⟩⟩⟩;
              simp [prod.lex_def, empty_relation]⟩⟩

theorem mul_assoc (a b c : ordinal) : a * b * c = a * (b * c) :=
quotient.induction_on₃ a b c $ λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩,
eq.symm $ quotient.sound ⟨⟨equiv.prod_assoc _ _ _, λ a b, begin
  cases a with a a₃, cases a with a₁ a₂,
  cases b with b b₃, cases b with b₁ b₂,
  simp [prod.lex_def, and_or_distrib_left, or_assoc, and_assoc]
end⟩⟩

theorem mul_add (a b c : ordinal) : a * (b + c) = a * b + a * c :=
quotient.induction_on₃ a b c $ λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩,
quotient.sound
  ⟨⟨equiv.sum_prod_distrib _ _ _,
    λ a b, by rcases a with ⟨a₁|a₁, a₂⟩; rcases b with ⟨b₁|b₁, b₂⟩;
              simp [prod.lex_def]⟩⟩

@[simp] theorem mul_succ (a b : ordinal) : a * succ b = a * b + a :=
by rw [succ, mul_add, mul_one]

theorem mul_le_mul_left {a b} (c : ordinal) : a ≤ b → c * a ≤ c * b :=
quotient.induction_on₃ a b c $ λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨f⟩, begin
  refine type_le'.2 ⟨order_embedding.of_monotone
    (λ a, (f a.1, a.2))
    (λ a b h, _)⟩, clear_,
  cases h with a₁ b₁ a₂ b₂ h' a b₁ b₂ h',
  { exact prod.lex.left _ _ _ (f.to_order_embedding.ord'.1 h') },
  { exact prod.lex.right _ _ h' }
end

theorem mul_le_mul_right {a b} (c : ordinal) : a ≤ b → a * c ≤ b * c :=
quotient.induction_on₃ a b c $ λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨γ, t, _⟩ ⟨f⟩, begin
  refine type_le'.2 ⟨order_embedding.of_monotone
    (λ a, (a.1, f a.2))
    (λ a b h, _)⟩,
  cases h with a₁ b₁ a₂ b₂ h' a b₁ b₂ h',
  { exact prod.lex.left _ _ _ h' },
  { exact prod.lex.right _ _ (f.to_order_embedding.ord'.1 h') }
end

theorem mul_lt_mul_of_pos_left {a b c : ordinal}
  (h : a < b) (c0 : 0 < c) : c * a < c * b :=
lt_of_lt_of_le
  (by simpa using (add_lt_add_iff_left (c*a)).2 c0)
  (mul_le_mul_left _ (succ_le.2 h))

theorem mul_pos {a b : ordinal} (h₁ : 0 < a) (h₂ : 0 < b) : 0 < a * b :=
by simpa using mul_lt_mul_of_pos_left h₂ h₁

theorem le_of_mul_le_mul_left {a b c : ordinal}
  (h : c * a ≤ c * b) (h0 : 0 < c) : a ≤ b :=
le_imp_le_iff_lt_imp_lt.2 (λ h', mul_lt_mul_of_pos_left h' h0) h

theorem mul_le_mul_iff_left {a b c : ordinal} (a0 : 0 < a) : a * b ≤ a * c ↔ b ≤ c :=
⟨λ h, le_of_mul_le_mul_left h a0, mul_le_mul_left _⟩

theorem mul_lt_mul_iff_left {a b c : ordinal} (a0 : 0 < a) : a * b < a * c ↔ b < c :=
le_iff_le_iff_lt_iff_lt.1 (mul_le_mul_iff_left a0)

theorem mul_left_inj {a b c : ordinal} (a0 : 0 < a) : a * b = a * c ↔ b = c :=
by simp [le_antisymm_iff, mul_le_mul_iff_left a0]

theorem mul_le_of_limit {a b c : ordinal.{u}}
  (h : is_limit b) : a * b ≤ c ↔ ∀ b' < b, a * b' ≤ c :=
⟨λ h b' l, le_trans (mul_le_mul_left _ (le_of_lt l)) h,
λ H, le_of_not_lt $
induction_on a (λ α r _, induction_on b $ λ β s _ h H l, begin
  suffices : ∀ a b, prod.lex s r (b, a) (enum _ _ l),
  { cases enum _ _ l with b a, exact irrefl _ (this _ _) },
  intros a b,
  rw [← typein_lt_typein (prod.lex s r), typein_enum],
  have := H _ (h.2 _ (typein_lt_type s b)),
  rw [mul_succ] at this,
  have := lt_of_lt_of_le ((add_lt_add_iff_left _).2
    (typein_lt_type _ a)) this,
  refine lt_of_le_of_lt (type_le'.2
    ⟨order_embedding.of_monotone (λ a, _) (λ a b, _)⟩) this,
  { rcases a with ⟨a, h⟩, cases a with b' a',
    by_cases e : b = b',
    { refine sum.inr ⟨a', _⟩,
      subst e, cases h with _ _ _ _ h _ _ _ h,
      { exact (irrefl _ h).elim },
      { exact h } },
    { refine sum.inl (⟨b', _⟩, a'),
      cases h with _ _ _ _ h _ _ _ h,
      { exact h }, { exact (e rfl).elim } } },
  { rcases a with ⟨a, h₁⟩, cases a with b₁ a₁,
    rcases b with ⟨b, h₂⟩, cases b with b₂ a₂,
    intro h, by_cases e₁ : b = b₁; by_cases e₂ : b = b₂,
    { substs b₁ b₂, simpa [prod.lex_def, @irrefl _ s _ b] using h },
    { subst b₁, simp [e₂, prod.lex_def] at h ⊢,
      cases h₂; [exact asymm h h₂_h, exact e₂ rfl] },
    { simp [e₁, e₂] },
    { simpa [e₁, e₂, prod.lex_def] using h } }
end) h H⟩

theorem mul_is_limit {a b : ordinal}
  (h : is_limit b) (a0 : 0 < a) : is_limit (a * b) :=
⟨ne_of_gt $ mul_pos a0 (pos_of_is_limit h),
λ c, le_imp_le_iff_lt_imp_lt.1 $ λ h', (mul_le_of_limit h).2 $ λ d h, begin
  refine succ_le_succ.1 (le_trans _ h'),
  rwa [succ_le, mul_lt_mul_iff_left a0],
end⟩

protected def div (a b : ordinal.{u}) : ordinal.{u} :=
if h : b = 0 then 0 else
@min.{(u+2) u} {o // a < b * succ o} ⟨⟨a, succ_le.1 $
  by simpa using mul_le_mul_right (succ a) (succ_le.2 (pos_iff_ne_zero.2 h))⟩⟩
  subtype.val

instance : has_div ordinal := ⟨ordinal.div⟩

@[simp] theorem div_zero (a : ordinal) : a / 0 = 0 := dif_pos rfl

def div_def (a) {b : ordinal} (h : b ≠ 0) : a / b =
  @min {o // a < b * succ o} _ subtype.val := dif_neg h

theorem lt_mul_succ_div (a) {b : ordinal} (h : b ≠ 0) : a < b * succ (a / b) :=
let ⟨⟨o, l⟩, e⟩ := @min_eq {o // a < b * succ o} _ _ in
by rwa [div_def a h, e]

theorem lt_mul_div_add (a) {b : ordinal} (h : b ≠ 0) : a < b * (a / b) + b :=
by simpa using lt_mul_succ_div a h

theorem div_le {a b c : ordinal} (b0 : b ≠ 0) : a / b ≤ c ↔ a < b * succ c :=
⟨λ h, lt_of_lt_of_le (lt_mul_succ_div a b0) (mul_le_mul_left _ $ succ_le_succ.2 h),
 λ h, by rw div_def a b0; exact @min_le {o // a < b * succ o} _ _ ⟨_, h⟩⟩

theorem lt_div {a b c : ordinal} (c0 : c ≠ 0) : a < b / c ↔ c * succ a ≤ b :=
by rw [← not_le, div_le c0, not_lt]

theorem le_div {a b c : ordinal} (c0 : c ≠ 0) :
  a ≤ b / c ↔ c * a ≤ b :=
begin
  apply limit_rec_on a,
  { simp [zero_le] },
  { intros, rw [succ_le, lt_div c0] },
  { simp [mul_le_of_limit, limit_le] {contextual := tt} }
end

theorem div_lt {a b c : ordinal} (b0 : b ≠ 0) :
  a / b < c ↔ a < b * c :=
le_iff_le_iff_lt_iff_lt.1 $ le_div b0

theorem div_le_of_le_mul {a b c : ordinal} (h : a ≤ b * c) : a / b ≤ c :=
if b0 : b = 0 then by simp [b0, zero_le] else
(div_le b0).2 $ lt_of_le_of_lt h $
mul_lt_mul_of_pos_left (lt_succ_self _) (pos_iff_ne_zero.2 b0)

theorem mul_lt_of_lt_div {a b c : ordinal} : a < b / c → c * a < b :=
le_imp_le_iff_lt_imp_lt.1 div_le_of_le_mul

@[simp] theorem zero_div (a : ordinal) : 0 / a = 0 :=
le_zero.1 $ div_le_of_le_mul $ by simp

theorem mul_div_le (a b : ordinal) : b * (a / b) ≤ a :=
if b0 : b = 0 then by simp [b0, zero_le] else (le_div b0).1 (le_refl _)

theorem mul_add_div (a) {b : ordinal} (b0 : b ≠ 0) (c) : (b * a + c) / b = a + c / b :=
begin
  apply le_antisymm,
  { apply (div_le b0).2,
    rw [mul_succ, mul_add, add_assoc, add_lt_add_iff_left],
    apply lt_mul_div_add _ b0 },
  { rw [le_div b0, mul_add, add_le_add_iff_left],
    apply mul_div_le }
end

theorem div_eq_zero_of_lt {a b : ordinal} (h : a < b) : a / b = 0 :=
by rw [← le_zero, div_le $ pos_iff_ne_zero.1 $ lt_of_le_of_lt (zero_le _) h];
   simpa using h

@[simp] theorem mul_div_cancel (a) {b : ordinal} (b0 : b ≠ 0) : b * a / b = a :=
by simpa using mul_add_div a b0 0

@[simp] theorem div_one (a : ordinal) : a / 1 = a :=
by simpa using mul_div_cancel a one_ne_zero

@[simp] theorem div_self {a : ordinal} (h : a ≠ 0) : a / a = 1 :=
by simpa using mul_div_cancel 1 h

instance : has_dvd ordinal := ⟨λ a b, ∃ c, b = a * c⟩

theorem dvd_def {a b : ordinal} : a ∣ b ↔ ∃ c, b = a * c := iff.rfl

theorem dvd_mul (a b : ordinal) : a ∣ a * b := ⟨_, rfl⟩

theorem dvd_zero (a : ordinal) : a ∣ 0 := ⟨_, (mul_zero _).symm⟩

theorem zero_dvd (a : ordinal) : 0 ∣ a ↔ a = 0 :=
⟨λ ⟨h, e⟩, by simp [e], λ e, e.symm ▸ dvd_zero _⟩

theorem one_dvd (a : ordinal) : 1 ∣ a := ⟨a, (one_mul _).symm⟩

theorem div_mul_cancel : ∀ {a b : ordinal}, a ≠ 0 → a ∣ b → a * (b / a) = b
| a _ a0 ⟨b, rfl⟩ := by rw [mul_div_cancel _ a0]

instance : has_mod ordinal := ⟨λ a b, a - b * (a / b)⟩

theorem mod_def (a b : ordinal) : a % b = a - b * (a / b) := rfl

@[simp] theorem mod_zero (a : ordinal) : a % 0 = a :=
by simp [mod_def]

theorem mod_eq_of_lt {a b : ordinal} (h : a < b) : a % b = a :=
by simp [mod_def, div_eq_zero_of_lt h]

@[simp] theorem zero_mod (b : ordinal) : 0 % b = 0 :=
by simp [mod_def]

theorem div_add_mod (a b : ordinal) : b * (a / b) + a % b = a :=
add_sub_cancel_of_le $ mul_div_le _ _

theorem mod_lt (a) {b : ordinal} (h : b ≠ 0) : a % b < b :=
(add_lt_add_iff_left (b * (a / b))).1 $
by rw div_add_mod; exact lt_mul_div_add a h

@[simp] theorem mod_self (a : ordinal) : a % a = 0 :=
if a0 : a = 0 then by simp [a0] else
by simp [mod_def, a0]

@[simp] theorem mod_one (a : ordinal) : a % 1 = 0 :=
by simp [mod_def]

end ordinal

namespace cardinal

def ord (c : cardinal) : ordinal :=
begin
  let ι := λ α, {r // is_well_order α r},
  have : ∀ α, nonempty (ι α) := λ α,
    ⟨classical.indefinite_description _ well_ordering_thm⟩,
  let F := λ α, ordinal.min (this _) (λ i:ι α, ⟦⟨α, i.1, i.2⟩⟧),
  refine quot.lift_on c F _,
  suffices : ∀ {α β}, α ≈ β → F α ≤ F β,
  from λ α β h, le_antisymm (this h) (this (setoid.symm h)),
  intros α β h, cases h with f, refine ordinal.le_min.2 (λ i, _),
  have := @order_embedding.is_well_order _ _
    (f ⁻¹'o i.1) _ ↑(order_iso.preimage f i.1) i.2,
  rw ← show ordinal.type (f ⁻¹'o i.1) = ⟦⟨β, i.1, i.2⟩⟧, from
    quot.sound ⟨order_iso.preimage f i.1⟩,
  exact ordinal.min_le (λ i:ι α, ⟦⟨α, i.1, i.2⟩⟧) ⟨_, _⟩
end

def ord_eq_min (α : Type u) : ord (mk α) =
  @ordinal.min _ _ (λ i:{r // is_well_order α r}, ⟦⟨α, i.1, i.2⟩⟧) := rfl

theorem ord_eq (α) : ∃ (r : α → α → Prop) [wo : is_well_order α r],
  ord (mk α) = @ordinal.type α r wo :=
let ⟨⟨r, wo⟩, h⟩ := @ordinal.min_eq _
  ⟨classical.indefinite_description _ well_ordering_thm⟩
  (λ i:{r // is_well_order α r}, ⟦⟨α, i.1, i.2⟩⟧) in
⟨r, wo, h⟩

theorem ord_le_type (r : α → α → Prop) [is_well_order α r] : ord (mk α) ≤ ordinal.type r :=
@ordinal.min_le _
  ⟨classical.indefinite_description _ well_ordering_thm⟩
  (λ i:{r // is_well_order α r}, ⟦⟨α, i.1, i.2⟩⟧) ⟨r, _⟩

theorem ord_le {c o} : ord c ≤ o ↔ c ≤ o.card :=
quotient.induction_on c $ λ α, ordinal.induction_on o $ λ β s _,
let ⟨r, _, e⟩ := ord_eq α in begin
  simp, split; intro h,
  { rw e at h, exact let ⟨f⟩ := h in ⟨f.to_embedding⟩ },
  { cases h with f,
    have g := order_embedding.preimage f s,
    have := order_embedding.is_well_order g,
    exact le_trans (ord_le_type _) (ordinal.type_le'.2 ⟨g⟩) }
end

theorem lt_ord {c o} : o < ord c ↔ o.card < c :=
by rw [← not_le, ← not_le, ord_le]

@[simp] theorem card_ord (c) : (ord c).card = c :=
quotient.induction_on c $ λ α,
let ⟨r, _, e⟩ := ord_eq α in by simp [e]

@[simp] theorem ord_le_ord {c₁ c₂} : ord c₁ ≤ ord c₂ ↔ c₁ ≤ c₂ :=
by simp [ord_le]

@[simp] theorem ord_lt_ord {c₁ c₂} : ord c₁ < ord c₂ ↔ c₁ < c₂ :=
by simp [lt_ord]

@[simp] theorem ord_zero : ord 0 = 0 :=
le_antisymm (ord_le.2 $ cardinal.zero_le _) (ordinal.zero_le _)

@[simp] theorem ord_nat (n : ℕ) : ord n = n :=
le_antisymm (ord_le.2 $ by simp) $ begin
  induction n with n IH,
  { apply ordinal.zero_le },
  { exact (@ordinal.succ_le n _).2 (lt_of_le_of_lt IH $
    ord_lt_ord.2 $ nat_cast_lt.2 (nat.lt_succ_self n)) }
end

@[simp] theorem lift_ord (c) : (ord c).lift = ord (lift c) :=
eq_of_forall_ge_iff $ λ o, le_iff_le_iff_lt_iff_lt.2 $ begin
  split; intro h,
  { rcases ordinal.lt_lift_iff.1 h with ⟨a, e, h⟩,
    rwa [← e, lt_ord, ← ordinal.lift_card, lift_lt, ← lt_ord] },
  { rw lt_ord at h,
    rcases ordinal.lift_down' (le_of_lt h) with ⟨o, rfl⟩,
    rw [← ordinal.lift_card, lift_lt] at h,
    rwa [ordinal.lift_lt, lt_ord] }
end

def ord.order_embedding : @order_embedding cardinal ordinal (<) (<) :=
order_embedding.of_monotone cardinal.ord $ λ a b, cardinal.ord_lt_ord.2

@[simp] theorem ord.order_embedding_coe :
  (ord.order_embedding : cardinal → ordinal) = ord := rfl

def aleph_idx.initial_seg : @initial_seg cardinal ordinal (<) (<) :=
@order_embedding.collapse cardinal ordinal (<) (<) _ cardinal.ord.order_embedding

def aleph_idx : cardinal → ordinal := aleph_idx.initial_seg

@[simp] theorem aleph_idx.initial_seg_coe :
  (aleph_idx.initial_seg : cardinal → ordinal) = aleph_idx := rfl

@[simp] theorem aleph_idx_lt {a b} : aleph_idx a < aleph_idx b ↔ a < b :=
aleph_idx.initial_seg.to_order_embedding.ord'.symm

@[simp] theorem aleph_idx_le {a b} : aleph_idx a ≤ aleph_idx b ↔ a ≤ b :=
by rw [← not_lt, ← not_lt, aleph_idx_lt]

theorem aleph_idx.init {a b} : b < aleph_idx a → ∃ c, aleph_idx c = b :=
aleph_idx.initial_seg.init _ _

def aleph_idx.order_iso : @order_iso cardinal.{u} ordinal.{u} (<) (<) :=
@order_iso.of_surjective cardinal.{u} ordinal.{u} (<) (<) aleph_idx.initial_seg.{u} $
(initial_seg.eq_or_principal aleph_idx.initial_seg.{u}).resolve_right $
λ ⟨o, e⟩, begin
  have : ∀ c, aleph_idx c < o := λ c, (e _).2 ⟨_, rfl⟩,
  refine ordinal.induction_on o _ this, intros α r _ h,
  let s := sup.{u u} (λ a:α, inv_fun aleph_idx (ordinal.typein r a)),
  apply not_le_of_gt (lt_succ_self s),
  have I : injective aleph_idx := aleph_idx.initial_seg.to_embedding.inj,
  simpa [left_inverse_inv_fun I (succ s)] using
    le_sup.{u u} (λ a, inv_fun aleph_idx (ordinal.typein r a))
      (ordinal.enum r _ (h (succ s))),
end

@[simp] theorem aleph_idx.order_iso_coe :
  (aleph_idx.order_iso : cardinal → ordinal) = aleph_idx :=
by delta aleph_idx.order_iso; simp

end cardinal

def order.cof (r : α → α → Prop) [is_refl α r] : cardinal :=
@cardinal.min {S : set α // ∀ a, ∃ b ∈ S, r a b}
  ⟨⟨set.univ, λ a, ⟨a, ⟨⟩, refl _⟩⟩⟩
  (λ S, mk S)

theorem order_iso.cof.aux {α : Type u} {β : Type v} {r s}
  [is_refl α r] [is_refl β s] (f : r ≃o s) :
  cardinal.lift.{u (max u v)} (order.cof r) ≤
  cardinal.lift.{v (max u v)} (order.cof s) :=
begin
  rw [order.cof, order.cof, lift_min, lift_min, cardinal.le_min],
  intro S, cases S with S H, simp [(∘)],
  refine le_trans (min_le _ _) _,
  { exact ⟨f ⁻¹' S, λ a,
    let ⟨b, bS, h⟩ := H (f a) in ⟨f.symm b, by simp [bS, f.ord', h]⟩⟩ },
  { exact lift_mk_le.{u v (max u v)}.2
    ⟨⟨λ ⟨x, h⟩, ⟨f x, h⟩, λ ⟨x, h₁⟩ ⟨y, h₂⟩ h₃,
      by congr; injection h₃ with h'; exact f.to_equiv.bijective.1 h'⟩⟩ }
end

theorem order_iso.cof {α : Type u} {β : Type v} {r s}
  [is_refl α r] [is_refl β s] (f : r ≃o s) :
  cardinal.lift.{u (max u v)} (order.cof r) =
  cardinal.lift.{v (max u v)} (order.cof s) :=
le_antisymm (order_iso.cof.aux f) (order_iso.cof.aux f.symm)

namespace ordinal

def sup {ι} (f : ι → ordinal) : ordinal :=
@ordinal.min {c // ∀ i, f i ≤ c}
  ⟨⟨(sup (cardinal.succ ∘ card ∘ f)).ord, λ i, le_of_lt $
    cardinal.lt_ord.2 (lt_of_lt_of_le (cardinal.lt_succ_self _) (le_sup _ _))⟩⟩
  (λ a, a.1)

theorem le_sup {ι} (f : ι → ordinal) (i) : f i ≤ sup f :=
by dsimp [sup]; cases min_eq _ _ with c hc; rw hc; exact c.2 i

theorem sup_le {ι} {f : ι → ordinal} {a} : sup f ≤ a ↔ ∀ i, f i ≤ a :=
⟨λ h i, le_trans (le_sup _ _) h,
 λ h, by dsimp [sup]; change a with (⟨a, h⟩:subtype _).1; apply min_le⟩

def bsup (o : ordinal.{u}) : (Π a < o, ordinal.{max u v}) → ordinal.{max u v} :=
match o, o.out, o.out_eq with
| _, ⟨α, r, _⟩, rfl, f := by exact sup (λ a, f (typein r a) (typein_lt_type _ _))
end

theorem bsup_le {o f a} : bsup.{u v} o f ≤ a ↔ ∀ i h, f i h ≤ a :=
match o, o.out, o.out_eq, f :
 ∀ o w (e : ⟦w⟧ = o) (f : Π (a : ordinal.{u}), a < o → ordinal.{(max u v)}),
   bsup._match_1 o w e f ≤ a ↔ ∀ i h, f i h ≤ a with
| _, ⟨α, r, _⟩, rfl, f := by rw [bsup._match_1, sup_le]; exact
  ⟨λ H i h, by simpa using H (enum r i h), λ H b, H _ _⟩
end

theorem le_bsup {o} (f : Π a < o, ordinal) (i h) : f i h ≤ bsup o f :=
bsup_le.1 (le_refl _) _ _

def power (a b : ordinal) : ordinal :=
limit_rec_on b 1 (λ _ IH, IH * a) (λ b _, bsup b)

local infix ` ^ ` := power

theorem power_zero (a : ordinal) : a ^ 0 = 1 :=
limit_rec_on_zero _ _ _

theorem power_succ (a b : ordinal) : a ^ succ b = a ^ b * a :=
limit_rec_on_succ _ _ _ _

theorem power_limit (a : ordinal) {b} (h : is_limit b) :
  a ^ b = bsup b (λ c _, a ^ c) :=
limit_rec_on_limit _ _ _ _ h

theorem power_le_of_limit {a b c : ordinal} (h : is_limit b) :
  a ^ b ≤ c ↔ ∀ b' < b, a ^ b' ≤ c :=
by rw [power_limit _ h, bsup_le]

theorem ord_card_le (o : ordinal) : (card o).ord ≤ o :=
cardinal.ord_le.2 (le_refl _)

def aleph'.order_iso := cardinal.aleph_idx.order_iso.symm

def aleph' : ordinal → cardinal := aleph'.order_iso

@[simp] theorem aleph'.order_iso_coe :
  (aleph'.order_iso : ordinal → cardinal) = aleph' := rfl

@[simp] theorem aleph'_lt {o₁ o₂ : ordinal.{u}} : aleph' o₁ < aleph' o₂ ↔ o₁ < o₂ :=
aleph'.order_iso.ord'.symm

@[simp] theorem aleph'_le {o₁ o₂ : ordinal.{u}} : aleph' o₁ ≤ aleph' o₂ ↔ o₁ ≤ o₂ :=
by rw [← not_lt, ← not_lt, aleph'_lt]

@[simp] theorem aleph'_aleph_idx (c : cardinal.{u}) : aleph' c.aleph_idx = c :=
by simpa using cardinal.aleph_idx.order_iso.to_equiv.inverse_apply_apply c

@[simp] theorem aleph_idx_aleph' (o : ordinal.{u}) : o.aleph'.aleph_idx = o :=
by simpa using cardinal.aleph_idx.order_iso.to_equiv.apply_inverse_apply o

@[simp] theorem aleph'_succ {o : ordinal.{u}} : aleph' (succ o) = (aleph' o).succ :=
le_antisymm
 (cardinal.aleph_idx_le.1 $
  by rw [aleph_idx_aleph', succ_le, ← aleph'_lt, aleph'_aleph_idx];
     apply cardinal.lt_succ_self)
 (cardinal.succ_le.2 $ aleph'_lt.2 $ ordinal.lt_succ_self _)

def aleph (o : ordinal) : cardinal := aleph' (omega + o)

@[simp] theorem nat_cast_le {m n : ℕ} : (m : ordinal) ≤ n ↔ m ≤ n :=
by rw [← cardinal.ord_nat, ← cardinal.ord_nat,
       cardinal.ord_le_ord, cardinal.nat_cast_le]

@[simp] theorem nat_cast_lt {m n : ℕ} : (m : ordinal) < n ↔ m < n :=
by simp [lt_iff_le_not_le, -not_le]

@[simp] theorem nat_cast_inj {m n : ℕ} : (m : ordinal) = n ↔ m = n :=
by simp [le_antisymm_iff]

@[simp] theorem nat_le_card {o} {n : ℕ} : (n : cardinal) ≤ card o ↔ (n : ordinal) ≤ o :=
⟨λ h, by rwa [← cardinal.ord_le, cardinal.ord_nat] at h,
 λ h, card_nat n ▸ card_le_card h⟩

@[simp] theorem nat_lt_card {o} {n : ℕ} : (n : cardinal) < card o ↔ (n : ordinal) < o :=
by rw [← succ_le, ← cardinal.succ_le, cardinal.nat_succ, nat_le_card]; refl

@[simp] theorem card_lt_nat {o} {n : ℕ} : card o < n ↔ o < n :=
le_iff_le_iff_lt_iff_lt.1 nat_le_card

@[simp] theorem card_le_nat {o} {n : ℕ} : card o ≤ n ↔ o ≤ n :=
le_iff_le_iff_lt_iff_lt.2 nat_lt_card

@[simp] theorem card_eq_nat {o} {n : ℕ} : card o = n ↔ o = n :=
by simp [le_antisymm_iff]

@[simp] theorem type_fin (n : ℕ) : @type (fin n) (<) _ = n :=
by rw [← card_eq_nat, card_type, mk_fin]

@[simp] theorem lift_nat_cast (n : ℕ) : lift n = n :=
by induction n; simp *

theorem lift_type_fin (n : ℕ) : lift (@type (fin n) (<) _) = n := by simp

theorem fintype_card (r : α → α → Prop) [is_well_order α r] [fintype α] : type r = fintype.card α :=
by rw [← card_eq_nat, card_type, fintype_card]

set_option eqn_compiler.zeta true
def cof (o : ordinal.{u}) : cardinal.{u} :=
quot.lift_on o (λ ⟨α, r, _⟩,
  @order.cof α (λ x y, ¬ r y x) ⟨λ a, by apply irrefl⟩) $
λ ⟨α, r, _⟩ ⟨β, s, _⟩ ⟨⟨f, hf⟩⟩, begin
  show @order.cof α (λ x y, ¬ r y x) ⟨_⟩ = @order.cof β (λ x y, ¬ s y x) ⟨_⟩,
  refine cardinal.lift_inj.1 (@order_iso.cof _ _ _ _ ⟨_⟩ ⟨_⟩ _),
  exact ⟨f, λ a b, not_congr hf⟩,
end

theorem le_cof_type [is_well_order α r] {c} : c ≤ cof (type r) ↔
  ∀ S : set α, (∀ a, ∃ b ∈ S, ¬ r b a) → c ≤ mk S :=
by dsimp [cof, order.cof, type, quotient.mk, quot.lift_on];
   rw [cardinal.le_min, subtype.forall]; refl

theorem cof_type_le [is_well_order α r] (S : set α) (h : ∀ a, ∃ b ∈ S, ¬ r b a) :
  cof (type r) ≤ mk S :=
le_cof_type.1 (le_refl _) S h

theorem lt_cof_type [is_well_order α r] (S : set α) (hl : mk S < cof (type r)) :
  ∃ a, ∀ b ∈ S, r b a :=
not_forall_not.1 $ λ h, not_le_of_lt hl $ cof_type_le S (λ a, not_ball.1 (h a))

theorem cof_eq (r : α → α → Prop) [is_well_order α r] :
  ∃ S : set α, (∀ a, ∃ b ∈ S, ¬ r b a) ∧ mk S = cof (type r) :=
begin
  have : ∃ i, cof (type r) = _,
  { dsimp [cof, order.cof, type, quotient.mk, quot.lift_on],
    apply cardinal.min_eq },
  exact let ⟨⟨S, hl⟩, e⟩ := this in ⟨S, hl, e.symm⟩,
end

theorem ord_cof_eq (r : α → α → Prop) [is_well_order α r] :
  ∃ S : set α, (∀ a, ∃ b ∈ S, ¬ r b a) ∧ type (subrel r S) = (cof (type r)).ord :=
let ⟨S, hS, e⟩ := cof_eq r, ⟨s, _, e'⟩ := cardinal.ord_eq S,
    T : set α := {a | ∃ aS : a ∈ S, ∀ b : S, s b ⟨_, aS⟩ → r b a} in
begin
  suffices,
  { refine ⟨T, this,
      le_antisymm _ (cardinal.ord_le.2 $ cof_type_le T this)⟩,
    rw [← e, e'],
    refine type_le'.2 ⟨order_embedding.of_monotone
      (λ a, ⟨a, let ⟨aS, _⟩ := a.2 in aS⟩) (λ a b h, _)⟩,
    rcases a with ⟨a, aS, ha⟩, rcases b with ⟨b, bS, hb⟩,
    change s ⟨a, _⟩ ⟨b, _⟩,
    refine ((trichotomous_of s _ _).resolve_left (λ hn, _)).resolve_left _,
    { exact asymm h (ha _ hn) },
    { intro e, injection e with e, subst b,
      exact irrefl _ h } },
  { intro a,
    have : {b : S | ¬ r b a} ≠ ∅ := let ⟨b, bS, ba⟩ := hS a in
      @set.ne_empty_of_mem S {b | ¬ r b a} ⟨b, bS⟩ ba,
    let b := (is_well_order.wf s).min _ this,
    have ba : ¬r b a := (is_well_order.wf s).min_mem _ this,
    refine ⟨b, ⟨b.2, λ c, not_imp_not.1 $ λ h, _⟩, ba⟩,
    rw [show ∀b:S, (⟨b, b.2⟩:S) = b, by intro b; cases b; refl],
    exact (is_well_order.wf s).not_lt_min _ this
      (is_order_connected.neg_trans r h ba) }
end

theorem cof_le_card (o) : cof o ≤ card o :=
induction_on o $ λ α r _, begin
  have : mk (@set.univ α) = card (type r) :=
    quotient.sound ⟨equiv.set.univ _⟩,
  rw ← this, exact cof_type_le set.univ (λ a, ⟨a, ⟨⟩, irrefl a⟩)
end

@[simp] theorem cof_zero : cof 0 = 0 := 
le_antisymm (by simpa using cof_le_card 0) (cardinal.zero_le _)

@[simp] theorem cof_eq_zero {o} : cof o = 0 ↔ o = 0 := 
⟨induction_on o $ λ α r _ z, by exact
  let ⟨S, hl, e⟩ := cof_eq r in type_eq_zero_iff_empty.2 $
  λ ⟨a⟩, let ⟨b, h, _⟩ := hl a in
  ne_zero_iff_nonempty.2 (by exact ⟨⟨_, h⟩⟩) (e.trans z),
λ e, by simp [e]⟩

@[simp] theorem cof_succ (o) : cof (succ o) = 1 := 
begin
  apply le_antisymm,
  { refine induction_on o (λ α r _, _),
    change cof (type _) ≤ _,
    rw [← (_ : mk _ = 1)], apply cof_type_le,
    { refine λ a, ⟨sum.inr ⟨()⟩, set.mem_singleton _, _⟩,
      rcases a with a|⟨⟨⟨⟩⟩⟩; simp [empty_relation] },
    { rw [cardinal.fintype_card, set.card_singleton], simp } },
  { rw [← cardinal.succ_zero, cardinal.succ_le],
    simpa [lt_iff_le_and_ne, cardinal.zero_le] using
      λ h, succ_ne_zero o (cof_eq_zero.1 (eq.symm h)) }
end

@[simp] theorem cof_eq_one_iff_is_succ {o} : cof.{u} o = 1 ↔ ∃ a, o = succ a := 
⟨induction_on o $ λ α r _ z, begin
  rcases cof_eq r with ⟨S, hl, e⟩, rw z at e,
  cases ne_zero_iff_nonempty.1 (by rw e; exact one_ne_zero) with a,
  refine ⟨typein r a, eq.symm $ quotient.sound
    ⟨order_iso.of_surjective (order_embedding.of_monotone _
      (λ x y, _)) (λ x, _)⟩⟩,
  { apply sum.rec; [exact subtype.val, exact λ _, a] },
  { rcases x with x|⟨⟨⟨⟩⟩⟩; rcases y with y|⟨⟨⟨⟩⟩⟩;
      simp [subrel, order.preimage, empty_relation],
    exact x.2 },
  { suffices : r x a ∨ ∃ (b : ulift unit), ↑a = x, {simpa},
    rcases trichotomous_of r x a with h|h|h,
    { exact or.inl h },
    { exact or.inr ⟨⟨()⟩, h.symm⟩ },
    { rcases hl x with ⟨a', aS, hn⟩,
      rw (_ : ↑a = a') at h, {exact absurd h hn},
      refine congr_arg subtype.val (_ : a = ⟨a', aS⟩),
      have := le_one_iff_subsingleton.1 (le_of_eq e),
      apply subsingleton.elim } }
end, λ ⟨a, e⟩, by simp [e]⟩

@[simp] theorem cof_add (a b : ordinal) : b ≠ 0 → cof (a + b) = cof b :=
induction_on a $ λ α r _, induction_on b $ λ β s _ b0, begin
  change cof (type _) = _,
  refine eq_of_forall_le_iff (λ c, _),
  rw [le_cof_type, le_cof_type],
  split; intros H S hS,
  { refine le_trans (H {a | sum.rec_on a (∅:set α) S} (λ a, _)) ⟨⟨_, _⟩⟩,
    { cases a with a b,
      { cases type_ne_zero_iff_nonempty.1 b0 with b,
        rcases hS b with ⟨b', bs, _⟩,
        exact ⟨sum.inr b', bs, by simp⟩ },
      { rcases hS b with ⟨b', bs, h⟩,
        exact ⟨sum.inr b', bs, by simp [h]⟩ } },
    { exact λ a, match a with ⟨sum.inr b, h⟩ := ⟨b, h⟩ end },
    { exact λ a b, match a, b with
        ⟨sum.inr a, h₁⟩, ⟨sum.inr b, h₂⟩, h := by congr; injection h
      end } },
  { refine le_trans (H (sum.inr ⁻¹' S) (λ a, _)) ⟨⟨_, _⟩⟩,
    { rcases hS (sum.inr a) with ⟨a'|b', bs, h⟩; simp at h,
      { cases h }, { exact ⟨b', bs, h⟩ } },
    { exact λ ⟨a, h⟩, ⟨_, h⟩ },
    { exact λ ⟨a, h₁⟩ ⟨b, h₂⟩ h,
        by injection h with h; congr; injection h } }
end

@[simp] theorem cof_cof (o : ordinal) : cof (cof o).ord = cof o :=
le_antisymm (le_trans (cof_le_card _) (by simp)) $
induction_on o $ λ α r _, by exact
let ⟨S, hS, e₁⟩ := ord_cof_eq r,
    ⟨T, hT, e₂⟩ := cof_eq (subrel r S) in begin
  rw e₁ at e₂, rw ← e₂,
  refine le_trans (cof_type_le {a | ∃ h, subtype.mk a h ∈ T} (λ a, _)) ⟨⟨_, _⟩⟩,
  { rcases hS a with ⟨b, bS, br⟩,
    rcases hT ⟨b, bS⟩ with ⟨c, cT, cs⟩, cases c with c cS,
    exact ⟨c, ⟨cS, cT⟩, is_order_connected.neg_trans r cs br⟩ },
  { exact λ ⟨a, h⟩, ⟨⟨a, h.fst⟩, h.snd⟩ },
  { exact λ ⟨a, ha⟩ ⟨b, hb⟩ h,
      by injection h with h; congr; injection h },
end

@[simp] theorem one_add_omega : 1 + omega.{u} = omega :=
begin
  refine le_antisymm _ (le_add_left _ _),
  rw [omega, one_eq_lift_type_unit, ← lift_add, lift_le, type_add],
  have : is_well_order unit empty_relation := by apply_instance, 
  refine ⟨order_embedding.collapse (order_embedding.of_monotone _ _)⟩,
  { apply sum.rec, exact λ _, 0, exact nat.succ },
  { intros a b, cases a; cases b;
    simp [empty_relation, nat.succ_pos, iff_true_intro nat.succ_lt_succ] },
end

@[simp] theorem one_add_of_omega_le {o} (h : omega ≤ o) : 1 + o = o :=
by rw [← add_sub_cancel_of_le h, ← add_assoc, one_add_omega]

end ordinal

namespace cardinal
open ordinal

@[simp] theorem ord_omega : ord.{u} omega = ordinal.omega :=
le_antisymm (ord_le.2 $ le_refl _) $
le_of_forall_lt $ λ o h, begin
  rcases ordinal.lt_lift_iff.1 h with ⟨o, rfl, h'⟩,
  rw [lt_ord, ← lift_card, ← lift_omega.{0 u},
      lift_lt, ← typein_enum (<) h'],
  exact lt_omega_iff_fintype.2 ⟨set.fintype_lt_nat _⟩
end

@[simp] theorem add_one_of_omega_le {c} (h : omega ≤ c) : c + 1 = c :=
by rw [add_comm, ← card_ord c, ← card_one,
       ← card_add, one_add_of_omega_le];
   rwa [← ord_omega, ord_le_ord]

end cardinal

namespace ordinal

theorem lt_omega {o : ordinal.{u}} : o < omega ↔ ∃ n : ℕ, o = n :=
by rw [← cardinal.ord_omega, cardinal.lt_ord, lt_omega]; simp

theorem nat_lt_omega (n : ℕ) : (n : ordinal) < omega :=
lt_omega.2 ⟨_, rfl⟩

theorem omega_is_limit : is_limit omega :=
⟨ne_of_gt (nat_lt_omega 0), λ o h,
  let ⟨n, e⟩ := lt_omega.1 h in
  by rw [e]; exact nat_lt_omega (n+1)⟩

theorem omega_le {o : ordinal.{u}} : omega ≤ o ↔ ∀ n : ℕ, (n : ordinal) ≤ o :=
⟨λ h n, le_trans (le_of_lt (nat_lt_omega _)) h,
 λ H, le_of_forall_lt $ λ a h,
   let ⟨n, e⟩ := lt_omega.1 h in
   by rw [e, ← succ_le]; exact H (n+1)⟩

theorem nat_lt_limit {o} (h : is_limit o) : ∀ n : ℕ, (n : ordinal) < o
| 0     := lt_of_le_of_ne (zero_le o) h.1.symm
| (n+1) := h.2 _ (nat_lt_limit n)

theorem omega_le_of_is_limit {o} (h : is_limit o) : omega ≤ o :=
omega_le.2 $ λ n, le_of_lt $ nat_lt_limit h n

end ordinal

namespace cardinal
open ordinal

theorem ord_is_limit {c} (co : omega ≤ c) : (ord c).is_limit :=
begin
  refine ⟨λ h, omega_ne_zero _, λ a, le_imp_le_iff_lt_imp_lt.1 _⟩,
  { rw [← ordinal.le_zero, ord_le] at h,
    simpa [le_zero] using le_trans co h },
  { intro h, rw [ord_le] at h ⊢,
    rwa [← @add_one_of_omega_le (card a), ← card_succ],
    rw [← ord_le, ← le_succ_of_is_limit, ord_le],
    { exact le_trans co h },
    { rw ord_omega, exact omega_is_limit } }
end

end cardinal
