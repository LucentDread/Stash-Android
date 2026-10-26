import 'package:flutter/widgets.dart';

/// [padding] plus the system navigation bar's height at the bottom.
///
/// The app draws edge to edge: a scroll view given its own padding no
/// longer adds the system insets, so its end would sit under Android's
/// navigation bar, out of reach. Zero under a bottom navigation bar,
/// which already takes the inset.
EdgeInsets withNavBar(BuildContext context, EdgeInsets padding) => padding
    .copyWith(bottom: padding.bottom + MediaQuery.paddingOf(context).bottom);
