//
//  ViewController.swift
//  Identiface-Sample
//
//  Created by Emmanuel Rayendra on 3/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import UIKit
import NDIWrapper
import SafariServices
import SwiftyJSON

class ViewController: UIViewController {
    
    // UI Outlets
    @IBOutlet var appLabel: UILabel!
    @IBOutlet var homeLabel: UILabel!
    @IBOutlet var nricField: UITextField!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var alternativeLoginButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet var validationNRICToggle: UISwitch!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    // UI styles
    let isDangerColor = UIColor(red:255/255.0, green:56/255.0, blue:96/255.0, alpha:1)
    
    // Identiface QuickStart API
    // Use the backend repo sample for this
    let baseURL = "https://developer.bio-api.singpass.gov.sg/api"
    let getSessionTokenAPI = "/face/verify/token"
    let validateResultAPI = "/face/verify/validate"
    
    // SingPass servers and SDK initialisations
    let streamingURL = "https://stg-bio-stream.singpass.gov.sg"
    var sessionToken = ""
    private var ndiWrapper: NDIWrapper!
    
    // Code begins here
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // app header label
        appLabel.text = "Login to Identiface"
        
        // loading indicator initialisation
        indicatorView.isHidden = true
        
        // progressBar initialisation
        progressBar.isHidden = true
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers![1].cornerRadius = 4
        progressBar.subviews[1].clipsToBounds = true
        
        // set an NRIC for quick testing
        nricField.text = "G2957839M"
        actionButton.layer.cornerRadius = 5
        
        nricField.isEnabled = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showLoggedinScreen") {
            let loggedInVC = segue.destination as! LoggedIn
            loggedInVC.userID = nricField.text
        }
    }
    
    func alertCreator(title: String, message: String, actions: [String]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for action in actions {
            alert.addAction(UIAlertAction(title: action, style: .default, handler: nil))
        }
        
        self.present(alert, animated: true)
    }
    
    func getSessionToken(nric: String, sessionCompletionHandler: @escaping (JSON?) -> Void) {
        let getSessionTokenURL = URL(string: baseURL + getSessionTokenAPI)!
        
        let params: [String: Any] = [
            "service_id": "SingPass",
            "user_id": nric,
            "pw":"ndi-api"
        ]
        
        var request = URLRequest(url: getSessionTokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let reqBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return
        }
        request.httpBody = reqBody
        request.timeoutInterval = 10
        
        let session = URLSession.shared
        
        print(request.httpBody!)
        
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            if let error = error {
                print("ERROR FETCH: \(error)")
            }
            
            if let response = response {
                print("RESPONSE: \(response)")
            }
            
            if let data = data {
                do {
                    let json = try JSON(data: data)
                    sessionCompletionHandler(json)
                } catch {
                    print(error)
                }
            }
        })
        
        task.resume()
        
    }
    
    func validateResult(nric: String, sessionToken: String, sessionCompletionHandler: @escaping (JSON?) -> Void) {
           let validateResultURL = URL(string: baseURL + validateResultAPI)!
           
           let params: [String: Any] = [
               "service_id": "SingPass",
               "user_id": nric,
               "pw":"ndi-api",
               "token": sessionToken
           ]
           
           var request = URLRequest(url: validateResultURL)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           guard let reqBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
               return
           }
           request.httpBody = reqBody
           request.timeoutInterval = 10
           
           let session = URLSession.shared
           
           print(request.httpBody!)
           
           let task = session.dataTask(with: request, completionHandler: {
               (data, response, error) in
               if let error = error {
                   print("ERROR FETCH: \(error)")
               }
               
               if let response = response {
                   print("RESPONSE: \(response)")
               }
               
               if let data = data {
                   do {
                       let json = try JSON(data: data)
                       sessionCompletionHandler(json)
                   } catch {
                       print(error)
                   }
               }
           })
           
           task.resume()
    }
    
    @IBAction func toggleNRIC(sender: UISwitch) {
        print(sender.isOn)
        nricField.text = sender.isOn ? "G2957839M" : "G2834561K"
    }

    
    @IBAction func loadFace(sender: AnyObject) {
        
        self.view.endEditing(true)
        
        homeLabel.textColor = UIColor.black
        
        if (sessionToken != "") {
            sdkDidInitialise()
        } else {
            if (nricField.text == "") {
                
                homeLabel.text = "Key in your NRIC/FIN number above."
                homeLabel.textColor = isDangerColor
                
            } else {
                
                homeLabel.text = "Verifying your NRIC..."
                
                // hide actionButton when no input errors
                actionButton.isHidden = true
                alternativeLoginButton.isHidden = true
                
                indicatorView.startAnimating()
                indicatorView.isHidden = false
                
                getSessionToken(nric: nricField.text!, sessionCompletionHandler: {response in
                    if let response = response {
                        
                        print(response)
                        
                        if (response["type"].string! == "success") {
                            DispatchQueue.main.async {
                                self.sessionToken = response["token"].string!
                                
                                // initialise SDK
                                self.ndiWrapper = NDIWrapper(streamingURL: self.streamingURL, sessionToken: self.sessionToken)

                                self.nricField.isEnabled = false
                                self.validationNRICToggle.isEnabled = false
                                self.actionButton.isHidden = false
                                self.indicatorView.isHidden = true
                                
                                self.actionButton.setTitle("Launch Face Verification", for: .normal)
                                self.actionButton.backgroundColor = UIColor.systemGreen
                                
                                self.homeLabel.text = "Let's begin face verification with SingPass Face."
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.resetSDKInitialisation()
                                
                                self.homeLabel.text = "Your NRIC/FIN doesn't exist in our database..."
                            }
                        }
                    }
                })
            }
        }
    }
    
    func sdkDidInitialise() {
            
        ndiWrapper.launchBioAuth(streamingURL: self.streamingURL, sessionToken: self.sessionToken, callback: { (status) in

            DispatchQueue.main.async {
                self.actionButton.isHidden = true
                self.progressBar.isHidden = false
            }
            
            switch status {
            // Failure handler, will post alert messages based on feedback
            case .failure(reason: _, feedbackCode: let feedbackCode):
                
                // FORCE PASS MATCHING FOR G2957839M -- will always return pass no matter who tries to match this NRIC
                if (self.nricField.text == "G2957839M") {
                    self.validateResult(nric: self.nricField.text!, sessionToken: self.sessionToken, sessionCompletionHandler: { response in
                            if let response = response {
                                print("====")
                                print(response)
                                
                                if (response["is_passed"].string == "true") {
                                    DispatchQueue.main.async {
                                        self.performSegue(withIdentifier: "showLoggedinScreen", sender: nil)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.alertCreator(title: "Unsuccessful", message: "Face verification was unsucessful", actions: ["Try again", "Cancel"])
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.resetSDKInitialisation()
                                }
                            }
                        }
                    )
                    break
                }
                
                // else
                print(status)
                DispatchQueue.main.async {
                    let error = ErrorMessages.init(feedbackCode: feedbackCode)
                    self.present(error.errorMessageCreator(), animated: true)
                    self.resetSDKInitialisation()
                    
                    self.actionButton.setTitle("Try again", for: .normal)
                    self.actionButton.backgroundColor = UIColor.systemBlue
                }
                break
            // Successful verification handler, next step is to call the validateResult API
            case .success(token: let token):
                if (token != self.sessionToken) {
                    let alert = UIAlertController(title: "Error", message: "Session Error. Please try again", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                    
                    DispatchQueue.main.async {
                        self.resetSDKInitialisation()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.homeLabel.text = "Verifying with SingPass servers..."
                    }
                    
                    if (self.nricField.text == "G2957839M") {
                        DispatchQueue.main.async {
                            self.resetSDKInitialisation()
                            self.performSegue(withIdentifier: "showLoggedinScreen", sender: nil)
                        }
                        break
                    }
                    
                    self.validateResult(nric: self.nricField.text!, sessionToken: token, sessionCompletionHandler: { response in
                            if let response = response {
                                print("====")
                                print(response)
                                
                                if (response["is_passed"].bool!) {
                                    DispatchQueue.main.async {
                                        self.performSegue(withIdentifier: "showLoggedinScreen", sender: nil)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.alertCreator(title: "Unsuccessful", message: "Face verification was unsucessful", actions: ["Try again", "Cancel"])
                                    }
                                }
                                
                                // Reset SDK
                                
                                DispatchQueue.main.async {
                                    self.resetSDKInitialisation()
                                }
                            }
                        }
                    )
                }
                break
//            case .error(error: let error):      // pending TECQ
//                print("ERROR!")
//                print(error)
//                self.alertCreator(title: "Error", message: error.localizedDescription, actions: ["Ok"])
//                DispatchQueue.main.async {
//                    self.resetSDKInitialisation()
//                }
//                break
            case .processing(progress: let progress, message: let progressMessage):
                DispatchQueue.main.async {
                    self.homeLabel.text = progressMessage
                    self.progressBar.setProgress(Float(progress), animated: true)
                    print(Float(progress))
                }
                break
            default:
                print(status)
                break
            }
        })
        
    }
    
    func resetSDKInitialisation() {
        self.sessionToken = ""
        
        self.actionButton.setTitle("Verify my identity", for: .normal)
        self.actionButton.backgroundColor = UIColor.systemBlue
        
        self.homeLabel.text = ""
        
        
        self.nricField.isEnabled = true
        self.validationNRICToggle.isEnabled = true
        self.actionButton.isHidden = false
        self.progressBar.isHidden = true
    }

    @IBAction func privacyStmtPressed(_ sender: UIButton) {
        if let url = URL(string: "https://go.gov.sg/singpass-identiface-data-privacy") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated:true, completion: nil)
        }
    }
    
    func userDidLogIn() {
        print("LOGGED IN")
    }

}
