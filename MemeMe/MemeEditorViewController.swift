//
//  MemeEditorViewController.swift
//  MemeMe
//
//  Created by Simon Kim on 4/8/16.
//  Copyright © 2016 Simon Kim. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var pickLabel: UILabel!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UIToolbar!
    @IBOutlet weak var toolBar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textAttribute(topTextField, str: "TOP")
        textAttribute(bottomTextField, str: "BOTTOM")
        shareButton.enabled = false
        cancelButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       
        // Disable camera button if camera is not available
        
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        
        // Subscribe to keyboard notifications to allow the view to raise when necessary
        self.subscribeToKeyboardNotifications()
        shareButton.enabled = imagePickerView.image != nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
     
        // Unsubscribe the keyboard notifications
        self.unsubscribeFromKeyboardNotifications()
    }
    
    
    /* Picking an image from the Album or Camera */
    
    
    @IBAction func pickAnImageFromAlbum(sender: AnyObject) {
        
        pickImage(.PhotoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(sender: AnyObject) {
        pickImage(.Camera)
    }
    
    // Codes for selecting an image with source type (.PhotoLibrary, .Camera, etc)
    func pickImage(sourceType: UIImagePickerControllerSourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = sourceType
        presentViewController(pickerController, animated: true, completion: nil)
    }
    
    
    // Assigning selected image to image view
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePickerView.image = image
        }
        
        dismissViewControllerAnimated(true, completion: nil)
        pickLabel.hidden = true
        cancelButton.enabled = true
    }
    
    // Dismiss pickerControl if cancelled
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /* Text Field Attributes */
    
    
    // Attributes for default text style
    let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName : UIFont(name: "Impact", size: 40)!,
        NSStrokeWidthAttributeName : NSNumber(float: -3.0)
    ]
    
    // Method to manage text attribute of top and bottom text fields
    func textAttribute(textField: UITextField, str: String) {
        textField.delegate = self
        textField.text = str
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .Center
    }
    
    //Remove the default text when editing
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
    }
    
    //Return key to escape from the text field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    /* Moving the keyboard */
    
    
    // Subscribe to observe keyboard notification
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MemeEditorViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MemeEditorViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // Unsubscribe to observe keyboard notification
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // Responses to the UIKeyboardWillShowNotification. From Udacity Forum.
    func keyboardWillShow(notification: NSNotification) {
        if bottomTextField.isFirstResponder(){
            self.view.frame.origin.y -= getKeyboardHeight(notification);
        }
        else if topTextField.isFirstResponder(){
            self.view.frame.origin.y = 0;
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if bottomTextField.isFirstResponder() {
            self.view.frame.origin.y = 0
        }
    }
    
    // Measure the height of the keyboard
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    
    /* Generate, save and share the created meme */
    
    
    // Generate meme without toolbar and navbar
    func generateMemedImage() -> UIImage {
        toolBar.hidden = true
        navBar.hidden = true
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawViewHierarchyInRect(view.frame, afterScreenUpdates: true)
        let memedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        toolBar.hidden = false
        navBar.hidden = false
        
        return memedImage
    }
    
    // Show activity View when share is selected
    @IBAction func shareMeme(sender: AnyObject) {
        let memedImage = generateMemedImage()
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activity, completed, items, error in
            if completed {
                //Save the image
                var meme = Meme(topText: self.topTextField.text!, botText: self.bottomTextField.text!, originalImage: self.imagePickerView.image!, memedImage: memedImage)
            }
                //Dismiss the view controller
                self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // Cancel all and reset
    @IBAction func cancelAll(sender: AnyObject) {
       
        textAttribute(topTextField, str: "TOP")
        textAttribute(bottomTextField, str: "BOTTOM")
        imagePickerView.image = nil
        pickLabel.hidden = false
        shareButton.enabled = false
        cancelButton.enabled = false
    }
    
    
}

