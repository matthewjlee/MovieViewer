//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Matthew Lee on 1/12/17.
//  Copyright © 2017 Matthew Lee. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errorMessage: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]? //maybe nothing at all (nil)
    var filteredData: [NSDictionary]!
    var endpoint: String!
    let refreshControl = UIRefreshControl()
    var hasLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //had to inherit uisearchbardelegate properties before declaring this
        searchBar.delegate = self
        self.filteredData = self.movies
        self.hasLoaded = true
        
        //need to set the view controller's data source and delegate as the cell (movie cell)
        errorMessage.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        
        networkRequest()
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        //add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    func networkRequest() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        //request is made
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                print(error)
                self.errorMessage.isHidden = false
                MBProgressHUD.hide(for: self.view, animated: true)
                self.refreshControl.endRefreshing()
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
                    self.tableView.reloadData() //network fetching works slower than loading a view controller
                    //end refreshing after request is complete
                    if self.hasLoaded == true {
                        self.refreshControl.endRefreshing()
                    }
                }
            }
        }
        task.resume()

    }
    
    func refreshControlAction (refreshControl: UIRefreshControl) {
        networkRequest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return movies?.count
        //movies number
        
        //optional binding
        if let filteredData = filteredData {
            return filteredData.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        if let filteredData = self.filteredData {
            let movie = filteredData[indexPath.row] //! means that you are absolutely positive that something exists at row
            let title = movie["title"] as! String
            let overview = movie["overview"] as! String
            let baseUrl = "https://image.tmdb.org/t/p/w500"
            if let posterPath = movie["poster_path"] as? String {
                let imageUrl = NSURL(string: baseUrl + posterPath)
                
                //fading in an image loaded from the network
                let imageRequest = NSURLRequest(url: imageUrl as! URL)
                
                cell.titleLabel.text = title
                cell.overviewLabel.text = overview
                //cell.posterView.setImageWith(imageUrl as! URL)
                
                cell.posterView.setImageWith(imageRequest as URLRequest, placeholderImage: nil,
                    success: { (imageRequest, imageResponse, image) -> Void in
                        
                        // imageResponse will be nil if the image is cached
                        if imageResponse != nil {
                            print("Image was NOT cached, fade in image")
                            cell.posterView.alpha = 0.0
                            cell.posterView.image = image
                            UIView.animate(withDuration: 1, animations: { () -> Void in
                                cell.posterView.alpha = 1.0
                            })
                        } else {
                            print("Image was cached so just update the image")
                            cell.posterView.image = image
                        }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    //do something
                })
            }
        }

        //print("row \(indexPath.rows)")
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
        
        self.tableView.reloadData()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController //detailviewcontroller is just uiviewcontroller (not subclass)
        detailViewController.movie = movie
        
        print("prepare for segue called")
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
