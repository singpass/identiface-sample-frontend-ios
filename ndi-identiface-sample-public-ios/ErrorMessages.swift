//
//  ErrorMessages.swift
//  ndi-identiface-sample-public-ios
//
//  Created by Emmanuel Rayendra on 7/8/20.
//  Copyright © 2020 Emmanuel Rayendra. All rights reserved.
//

import Foundation
import UIKit

class ErrorMessages {
    
    var feedbackCode: String
    
    init(feedbackCode: String) {
        self.feedbackCode = feedbackCode
    }
    
    func alertCreator(title: String, message: String, actions: [String]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for action in actions {
            alert.addAction(UIAlertAction(title: action, style: .default, handler: nil))
        }
        
        return alert
    }
    
    func errorMessageCreator() -> UIAlertController {
        var alert: UIAlertController!
        
        switch self.feedbackCode {
        case "ambiguous_outcome":
            alert = self.alertCreator(title: "Unsuccessful Verification", message: "Try scanning again, or use another method to verify yourself.", actions: ["Scan again", "Cancel"])
            break
        case "client_browser":
            alert = self.alertCreator(title: "Unsuccessful Verification", message: "Try scanning again, or use another method to verify yourself.", actions: ["Scan again", "Cancel"])
            break
        default:
            alert = self.alertCreator(title: "Unsuccessful Verification", message: "Try scanning again, or use another method to verify yourself.", actions: ["Scan again", "Cancel"])
            break
        }
        
        return alert
    }
}
