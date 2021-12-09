//
//  UserLoginView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 08/11/2021.
//

import SwiftUI
import AuthenticationServices

struct UserLoginView: View {
    
    struct IdentifiableString: Identifiable {
        let id: UUID = .init()
        let value: String
    }
    
    @State
    var email: String = ""
    
    @State
    var password: String = ""
    
    @State
    var siwaEmail: IdentifiableString?
    
    var body: some View {
        ScrollView {
            VStack {
                TextField("Email", text: $email)
                
                SecureField("Passowrd", text: $password)
                
                SignInWithAppleButton(onRequest: onSiwaRequest, onCompletion: onSiwaCompletion)
            }
        }.sheet(item: $siwaEmail, onDismiss: nil) { siwaEmail in
            SiwaCreateUsernameView(siwaEmail: siwaEmail.value)
        }
        
    }
    
    func onSiwaRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.email]
    }
    
    func onSiwaCompletion(_ result: Result<ASAuthorization, Error>) {
        do {
            switch result {
            case .success(let auth):
                guard let creds = auth.credential as? ASAuthorizationAppleIDCredential else {
                    throw GenericError(reason: "Unable to decode login")
                }
                guard let userEmail = creds.email else {
                    throw GenericError(reason: "Missing user emial")
                }
                self.siwaEmail = .init(value: userEmail)
            case .failure(let error):
                throw error
            }
        } catch {
            print(error)
        }
    }
}

struct UserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        UserLoginView()
    }
}
