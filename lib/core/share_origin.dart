import 'package:flutter/widgets.dart';

/// iPad renders the share sheet as a popover and needs an anchor rectangle.
/// Without one, `share_plus` throws at the platform channel — a crash that
/// never reproduces on a phone or in the simulator's iPhone profiles.
///
/// Every `SharePlus.instance.share(...)` call must pass
/// `sharePositionOrigin: context.shareOrigin`.
extension ShareOrigin on BuildContext {
  /// The global rect of this context's render box, or null if it has not been
  /// laid out. `share_plus` treats null as "no anchor", which is correct on
  /// phones and only unsafe on iPad — so callers should prefer a context that
  /// is actually mounted and painted.
  Rect? get shareOrigin {
    final box = findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
