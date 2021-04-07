//
//  ViewController.swift
//  CameraApp
//
//  Created by Okhunov Odil on 2020/12/18.
//

import UIKit
import RealmSwift


class ViewController: UIViewController{
    
    let realm = try! Realm()

    //declaring imagePicker as UIImagePickerController
    let imagePicker = UIImagePickerController()
    //for documents url
    var documentsURL: URL {return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!}
    var fileNames = [String]()
    var categories: Results<FileData>?

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ItemsCell", bundle: nil), forCellReuseIdentifier: "cell")
        loadCategories()
        //imagePicker's delegate equals to current class
        imagePicker.delegate = self
        //imagePicker's source type is camera
        imagePicker.sourceType = .camera
        //defining the media types
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        //when you shoot a photo you can crop the image by allowing editing = true or use the original not edited image false.
        imagePicker.allowsEditing = false
    }

    @IBAction func cameraButton(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func getImageFromDatabase(fileName: String) -> UIImage? {
          
          let fileURL = self.documentsURL.appendingPathComponent(fileName)
          
          do {
              let imageData = try Data(contentsOf: fileURL)
              
              return UIImage(data: imageData)
              
          } catch {
              
              return nil
          }
      }
    
    func save(category: FileData) {
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("Error saving category \(error)")
        }
        tableView.reloadData()
    }
    
    func loadCategories() {
        
        categories = realm.objects(FileData.self)
        tableView.reloadData()
    }
    
    func updateModel(at indexPath: IndexPath) {
        if let categoryForDeletion = self.categories?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(categoryForDeletion)
                }
            } catch {
                print("Error deleting category, \(error)")
            }
        }
    }
    
    func deleteAction(at indexPath: IndexPath) -> UIContextualAction{
        
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            if let file_name_path = self.categories?[indexPath.row].file_name{
                self.deleteImageFromDatabase(fileName: file_name_path)
            }
            
            self.updateModel(at: indexPath)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.reloadData()
            completion(true)
        }
        action.image = UIImage(systemName: "trash")
        
        return action
    }
    func deleteImageFromDatabase(fileName: String){
           
           var filePath = ""
           let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
           let documentDirectory = paths[0]
           filePath = documentDirectory.appendingFormat("/" + fileName)
           
           do {
               
               let fileManager = FileManager.default
               if fileManager.fileExists(atPath: filePath) {
                   
                   try fileManager.removeItem(atPath: filePath)
                
               } else {
                   print("File does not exist")
               }

           } catch {
               print(error)
           }
       }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //delegate function which happens after you shoot or select a certain image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else{ return }
        let fileName = UUID().uuidString
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        if let imageData = userPickedImage.pngData() {
            try? imageData.write(to: fileURL, options: .atomic)
            let fileData = FileData()
            fileData.file_name = fileName
            self.save(category: fileData)
            print(fileName)
        }
      
        //to dismiss imagePicker
        imagePicker.dismiss(animated: true, completion: nil)
        tableView.reloadData()
    }
}
//502DE7B8-55B5-4561-8992-19664C2680AB
//2F54585B-E2A7-456F-AD45-253EB5FB0D04
//A1D8AADF-5135-40C9-9CCF-F9E671701467

extension  ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ItemsCell
        if let file_name_path = categories?[indexPath.row].file_name{
            cell.cellImage.image = getImageFromDatabase(fileName: file_name_path)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = deleteAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
}
