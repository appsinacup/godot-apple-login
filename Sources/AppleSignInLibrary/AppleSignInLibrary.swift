import Foundation
import SwiftGodot
import AuthenticationServices

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// The delegate is required for both iOS and macOS — presentation API differs by platform so
// we compile the implementation for both platforms.
#if os(iOS) || os(macOS)
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onSuccess: ((String, String?, String?) -> Void)?
    var onError: ((String) -> Void)?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        // On iOS we try to use the first connected UIWindowScene -> window pair.
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No valid window found")
        }
        return window
        #elseif os(macOS)
        // On macOS we return the key or main NSWindow or the first visible window we can find.
        if let win = NSApp.keyWindow ?? NSApp.mainWindow {
            return win
        }

        for win in NSApp.windows where win.isVisible {
            return win
        }

        fatalError("No valid NSWindow found")
        #endif
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onError?(error.localizedDescription)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            let id = credentials.user
            let email = credentials.email
            let name = "\(credentials.fullName?.givenName ?? "") \(credentials.fullName?.familyName ?? "")"
                .trimmingCharacters(in: .whitespaces)
            UserDefaults.standard.set(id, forKey: "id")
            onSuccess?(id, email, name)
        default:
            onError?("Received unknown credential type")
        }
    }
}
#endif

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [AppleSignInLibrary.self]
)

@Godot
class AppleSignInLibrary: RefCounted {
    #if os(iOS) || os(macOS)
    private var signInDelegate: AppleSignInDelegate?
    #endif
    
    @Signal var Output: SignalWithArguments<String, String, String, String>
    
    let center = NotificationCenter.default
    let name = ASAuthorizationAppleIDProvider.credentialRevokedNotification
    
    @Callable
    func signIn() {
        #if os(iOS) || os(macOS)
        signInDelegate = AppleSignInDelegate()
        
        signInDelegate?.onSuccess = { [weak self] id, email, name in
            guard let self = self else { return }
            Output.emit(id, email ?? "", name ?? "", "")
        }
        
        signInDelegate?.onError = { [weak self] error in
            guard let self = self else { return }
            Output.emit("", "", "", error)
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = signInDelegate
        controller.presentationContextProvider = signInDelegate
        controller.performRequests()
        #else
        Output.emit("", "", "", "Apple sign in is not supported on this platform")
        #endif
    }
}
