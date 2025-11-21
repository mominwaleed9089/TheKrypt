import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    /// iOS 16+: uses `.scrollDismissesKeyboard(.interactively)`
    /// Older iOS: falls back to a drag gesture that resigns first responder
    @ViewBuilder
    func autoDismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self.simultaneousGesture(
                DragGesture().onChanged { _ in
                    hideKeyboard()
                }
            )
        }
    }
}
