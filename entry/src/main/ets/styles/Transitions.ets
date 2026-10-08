// Create independent effects: TransitionEffect chains are mutable.
export function contentAppearTransition(): TransitionEffect {
  const appear = TransitionEffect.opacity(0)
    .combine(TransitionEffect.translate({ y: 8 }));
  return TransitionEffect.asymmetric(appear, TransitionEffect.IDENTITY)
    .animation({ duration: 200, curve: Curve.EaseOut });
}

export function feedbackTransition(): TransitionEffect {
  const appear = TransitionEffect.opacity(0)
    .combine(TransitionEffect.translate({ y: 6 }));
  return TransitionEffect.asymmetric(appear, TransitionEffect.opacity(0))
    .animation({ duration: 180, curve: Curve.EaseOut });
}

export function listItemTransition(): TransitionEffect {
  return TransitionEffect.opacity(0)
    .animation({ duration: 180, curve: Curve.EaseOut });
}
