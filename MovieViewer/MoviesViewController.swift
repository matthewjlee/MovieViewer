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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //had to inherit uisearchbardelegate properties before declaring this
        searchBar.delegate = self
        
        //initialize ui refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        //add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    func refreshControlAction (refreshControl: UIRefreshControl) {
        //need to set the view controller's data source and delegate as the cell (movie cell)
        errorMessage.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
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
                self.errorMessage.isHidden = false
                MBProgressHUD.hide(for: self.view, animated: true)
                refreshControl.endRefreshing()
                return
            }
            
            //request is complete
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    //movies = dataDictionary won't work cuz not dictionary
                    self.movies = (dataDictionary["results"] as! [NSDictionary])
                    self.tableView.reloadData() //network fetching works slower than loading a view controller
                    //end refreshing after request is complete
                    refreshControl.endRefreshing()
                }
            }
        }
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return movies?.count
        //movies number
        
        //optional binding
        if let movies = movies {
            return movies.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies![indexPath.row] //! means that you are absolutely positive that something exists at row
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        let baseUrl = "https://image.tmdb.org/t/p/w500"
        let posterPath = movie["poster_path"] as! String
        let imageUrl = NSURL(string: baseUrl + posterPath)
        
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.posterView.setImageWith(imageUrl as! URL)
        print("row \(indexPath.row)")
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var movieTitles: [String]?
        if let count = movies?.count {
            for index in 0..<count {
                let movie = movies![index]
                movieTitles?.append(movie["title"] as! String)
            }
        }
        
        print(movies?.count)
        
        for i in 0..<5 {
            print(movieTitles?[i])
        }
        
        var filteredData: [String]!
        filteredData = searchText.isEmpty ? movieTitles : movieTitles?.filter({(dataString: String) -> Bool in
            return dataString.range(of: searchText, options: .caseInsensitive) != nil
        })
        
        self.tableView.reloadData()
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
