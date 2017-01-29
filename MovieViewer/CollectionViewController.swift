//
//  CollectionViewController.swift
//  MovieViewer
//
//  Created by Matthew Lee on 1/16/17.
//  Copyright © 2017 Matthew Lee. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class CollectionViewController: UIViewController, UICollectionViewDelegate, UISearchBarDelegate {

    var movies: [NSDictionary]? //maybe nothing at all (nil)
    var filteredData: [NSDictionary]!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.dataSource = self
        
        //had to inherit uisearchbardelegate properties before declaring this
        searchBar.delegate = self
        self.filteredData = self.movies
    
        //need to set the view controller's data source and delegate as the cell (movie cell)
        //errorMessage.isHidden = true
        collectionView.dataSource = self
        collectionView.delegate = self
        //console will only print cells that are visible
        // Do any additional setup after loading the view.
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        //request is made
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                print(error)
                //self.errorMessage.isHidden = false
                MBProgressHUD.hide(for: self.view, animated: true)
                //refreshControl.endRefreshing()
                return
            }
            
            //request is complete
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    //movies = dataDictionary won't work cuz not dictionary
                    self.movies = (dataDictionary["results"] as! [NSDictionary])
                    self.filteredData = self.movies
                    self.collectionView.reloadData() //network fetching works slower than loading a view controller
                    //end refreshing after request is complete
                    //refreshControl.endRefreshing()
                }
            }
        }
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredData?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionCell", for: indexPath as IndexPath) as! MovieCollectionCell
        
        
        if let filteredData = self.filteredData {
            let movie = filteredData[indexPath.row] //! means that you are absolutely positive that something exists at row
            let title = movie["title"] as! String
            let overview = movie["overview"] as! String
            let baseUrl = "https://image.tmdb.org/t/p/w500"
            let posterPath = movie["poster_path"] as! String
            let imageUrl = NSURL(string: baseUrl + posterPath)
            
            //fading in an image loaded from the network
            let imageRequest = NSURLRequest(url: imageUrl as! URL)
            
            
            cell.image.setImageWith(imageUrl as! URL)
        }
        
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("reach here")
        if searchText.isEmpty {
            self.filteredData = self.movies
            
        } else {
            if let movies = movies as? [[String: Any]] {
                self.filteredData = []
                for movie in movies {
                    if let title = movie["title"] as? String {
                        if (title.range(of: searchText, options: .caseInsensitive) != nil) {
                            self.filteredData.append(movie as NSDictionary)
                        }
                    }
                }
            }
        }
        
        self.collectionView.reloadData()
    }
}

