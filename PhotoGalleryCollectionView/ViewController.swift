//
//  ViewController.swift
//  PhotoGalleryCollectionView
//
//  Created by Macintosh on 2017/11/27.
//  Copyright © 2017年 club.animalnote. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

class ViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITabBarDelegate {
    
    var imageArray = [UIImage]()
    var urlArray = [String]()
    
    var photoAssets = [PHAsset]()
    // PHAssetのリスト変数
    var photoAssets2: Array<PHAsset> = Array<PHAsset>()
    
    var photoUrl = [NSString]()

    //var refreshControl: UIRefreshControl = UIRefreshControl()
    var refreshControl:UIRefreshControl!

    @IBOutlet weak var myImageView: UIImageView!
    
    @IBOutlet weak var colViewCell: UICollectionView!
    
    @IBOutlet weak var assetsData: UILabel!
    
    @IBOutlet weak var TabBar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //デリゲート先を自分に設定する。
        TabBar.delegate = self
        
        let myBoundSize: CGSize = UIScreen.mainScreen().bounds.size
        let myBoundSizeStr: NSString = "Bounds width: \(myBoundSize.width) height: \(myBoundSize.height)"
        
        print (myBoundSizeStr)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
        //let db = FMDatabase(path: pathx)
        //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
        let db = FMDatabase(path: _pathx)
        //let db = NSFileManager.defaultManager().fileExistsAtPath(_pathx)
        
        if db == true {
            print("already create data base")
        }else{
            print("create database")
        }
        
        db.open()
        
        let sql = "CREATE TABLE IF NOT EXISTS photo_mst (pic_name TEXT PRIMARY KEY, pic_url TEXT, pic_path TEXT, pic_date TEXT, pic_bunrui TEXT, pic_comment TEXT);"
        let ret = db.executeUpdate(sql, withArgumentsInArray: nil)
        
        // read data
        let sql2 = "SELECT pic_name, pic_url, pic_date FROM photo_mst order by pic_date;"
        let results = db.executeQuery(sql2, withArgumentsInArray: nil)
        
        //print(results.next())
        
        if(results.columnCount() > 0){
            //var cnt = 0
            while results.next() {
                //cnt++
                //s
                print(results.stringForColumn("pic_name")+":"+results.stringForColumn("pic_url"))
                //cnt = Int(results.intForColumnIndex(0) as Int32)
                //print(cnt)
            }
            //print(cnt)
        }
        
        db.close()
        
        
        
        //getAllPhotosInfo()
        
//        if let firstAsset = self.photoAssets2[0] {
//            // directoryに、画像保存場所パスを入れる
//            let directory: String = firstAsset.value(forKey: "directory") as! String
//        }
       
        grabPhotos()
        colViewCell.delegate = self
        colViewCell.dataSource = self
        
        
        // リフレッシュコントロールの設定をしてテーブルビューに追加
//        refreshControl = UIRefreshControl()
//        refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
//        //self.refreshControl.addTarget(self, action: #selector(ViewController.refresh2), forControlEvents: UIControlEvents.ValueChanged)
//        refreshControl.addTarget(self, action: "refresh2:", forControlEvents: UIControlEvents.ValueChanged)
//        
//        colViewCell.addSubview(refreshControl)
//        //refreshControl.endRefreshing()
//        
//        //grabPhotos()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
        self.refreshControl.addTarget(self, action: #selector(ViewController.refresh2), forControlEvents: UIControlEvents.ValueChanged)
        //self.refreshControl.addTarget(self, action: #selector(ViewController.refresh2), forControlEvents: UIControlEvents.valueChanged)
        colViewCell.addSubview(refreshControl)
        
    }
    
    //ボタン押下時の呼び出しメソッド
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem){
        switch item.tag {
        case 1:
            print("case1")
            //全データ生成
            dbupdate()
            
            break
        case 2:
            print("case2")
            //全データチェック
            dbcheck()
            
            break
        case 3:
            print("case3")
            
            dbdelete()
            
//            let cameraViewController2 = self.storyboard?.instantiateViewControllerWithIdentifier("cameraView2") as!CameraViewController2
//            self.presentViewController(cameraViewController2, animated: true, completion: nil)
            break
            
        default:
            return
        }
    }
    private func getAllPhotosInfo() {
        photoAssets = []
        
        // 画像をすべて取得
        
        var assets: PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        assets.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            self.photoAssets.append(asset as! PHAsset)

        }
        print(photoAssets)
    }
    
    //http://www.codechannels.com/video/archetapp/instagram/photo-album-in-collection-view-swift-2-in-xcode/下記grabPhotos参照
    func grabPhotos(){
        
        //データベースオープン
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
        //let db = FMDatabase(path: pathx)
        //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
        let db = FMDatabase(path: _pathx)
        //let db = NSFileManager.defaultManager().fileExistsAtPath(_pathx)
        
        if db == true {
            print("already create data base")
        }else{
            print("create database")
        }
        
        db.open()
        let sql3 = "INSERT INTO photo_mst (pic_name,pic_url,pic_path,pic_date,pic_bunrui,pic_comment) VALUES (?, ?, ?, ?, ?, ?);"
        
        photoAssets = []
        let imgManager = PHImageManager.defaultManager()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        requestOptions.deliveryMode = .HighQualityFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if let fetchResult : PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions){
            
            if fetchResult.count > 0 {
                
                for i in 0..<fetchResult.count{
                    //print(fetchResult.indexOfObject(imgManager))
                    imgManager.requestImageForAsset(fetchResult.objectAtIndex(i) as! PHAsset, targetSize: CGSize(width: 200, height: 200), contentMode: .AspectFill, options: requestOptions, resultHandler:
                        {
                        image, error in
                        
                            self.imageArray.append(image!)
                            self.photoAssets.append(fetchResult.objectAtIndex(i) as! PHAsset)
                            let arry = fetchResult.objectAtIndex(i).localIdentifier.componentsSeparatedByString("/L0/001")
                            self.urlArray.append(arry[0])
                            let date:NSDate? = fetchResult.objectAtIndex(i).creationDate
                            //self.photoUrl.append(PHAsset.defaultRepresentation().url())
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
                            let str:String = dateFormatter.stringFromDate(date!)
                            //print(arry[0]+str)
                            //強制的にデータベースへ追加登録
                            //db.executeUpdate(sql3, withArgumentsInArray: [arry[0],"test","test",str,"test","test"])
                    })
                    
                    
                    
                }
                
            }
            
        }
        else{
            print("You got no photos!")
            self.colViewCell.reloadData()
            
        }
        
    }
    
    func getURL(ofPhotoWith mPhasset: PHAsset) {
        
//        if mPhasset.mediaType == .video {
//            let options: PHVideoRequestOptions = PHVideoRequestOptions()
//            options.deliveryMode = .highQualityFormat
//            options.version = .original
//            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
//            print(info)
//            })
//        }
    }
    
    func refresh2() {
        print("refresh2")
        imageArray.removeAll()
        grabPhotos()
        self.colViewCell.reloadData()
        // ここに通信処理などデータフェッチの処理を書く
        // データフェッチが終わったらUIRefreshControl.endRefreshing()を呼ぶ必要がある
        refreshControl.endRefreshing()
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: ColViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ColViewCell
        
        //let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        cell.imgCell.image = imageArray[indexPath.row]
        
        return cell
    }
    
    //cellが選択された場合
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let url = NSURL(string: "assets-library://asset/asset.JPG?id=" + urlArray[indexPath.row] + "=JPG");
        let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithALAssetURLs([url!], options: nil)
        
        
        let asset: PHAsset = fetchResult.firstObject as! PHAsset
        let manager = PHImageManager.defaultManager()
        let assetLib = ALAssetsLibrary()
        assetLib.assetForURL(url, resultBlock: { (asset:ALAsset!) -> Void in
            
        let metadata = asset.defaultRepresentation().metadata()
            //print("metadata")
        print(metadata)
            //self.urlText.text = String(metadata)
            //self.urlText.text = self.photoAssets[indexPath.row].creationDate as? String
            
            
            if metadata[kCGImagePropertyGPSDictionary] == nil {
                //print("Location data nothing")
                self.assetsData.text = "Location data nothing"
            }else{
                let gps = metadata[kCGImagePropertyGPSDictionary] as! [NSObject: AnyObject]
                let lat = gps[kCGImagePropertyGPSLatitude] as! Double
                let lng = gps[kCGImagePropertyGPSLongitude] as! Double
                
                //NSLog("GPS Info Lat:%f Lng:%f", lat,lng)
                self.assetsData.text = "Lat:" + String(lat) + " Log:" + String(lng)
            }
            
            //self.dismissViewControllerAnimated(true, completion: nil)
            
        }) { (error:NSError!) -> Void in
            
        }
        
        manager.requestImageForAsset(asset,targetSize: PHImageManagerMaximumSize,contentMode: PHImageContentMode.AspectFill,options:nil) { (image, info) in
                // imageにUIImageが渡ってきます
                self.myImageView.image = self.cropImageToSquare(image!)
        }
        
//        manager.requestImageForAsset(asset, targetSize: CGSize(width: 140, height: 140), contentMode: .AspectFill, options: nil) { (image, info) in
//            // imageをセットする
//            self.myImageView.image = image
//        }
//        let manager: PHImageManager = PHImageManager()
//        let asset = photoAssets[indexPath.row]
//        print("select photoAssets")
//        print(asset)
//        
//        manager.requestImageForAsset(asset,
//                                     targetSize: PHImageManagerMaximumSize,
//                                     contentMode: PHImageContentMode.AspectFill,
//                                     options: nil) { (image, info) in
//                                        // imageにUIImageが渡ってきます
//                                        self.myImageView.image = self.cropImageToSquare(image!)
//        }
//        print("Cell \(asset) selected")
//        
//        //myImageView.image = imageArray[indexPath.row]
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        //４列表示で１ドット分隙間に設定
        let width: CGFloat = view.frame.width / 4 - 1
        let height: CGFloat = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func cropImageToSquare(image: UIImage) -> UIImage? {
        if image.size.width > image.size.height {
            // 横長
            let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(image.size.width/2 - image.size.height/2, 0, image.size.height, image.size.height))
            
            return UIImage(CGImage: cropCGImageRef!)
        } else if image.size.width < image.size.height {
            // 縦長
            let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, image.size.width, image.size.width))
            
            return UIImage(CGImage: cropCGImageRef!)
        } else {
            return image
        }
    }
    
    func dbdelete(){
        
        //データベースオープン
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
        //let db = FMDatabase(path: pathx)
        //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
        let db = FMDatabase(path: _pathx)
        //let db = NSFileManager.defaultManager().fileExistsAtPath(_pathx)
        
        if db == true {
            print("already create data base")
        }else{
            print("create database")
        }
        
        db.open()
        
        print("DELETE FROM photo_mst;")
        
        let sql = "DELETE FROM photo_mst;"
        
        let ret = db.executeUpdate(sql, withArgumentsInArray: nil)
        db.close()
        
    }
    
    
    func dbcheck(){
        
        //データベースオープン
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
        //let db = FMDatabase(path: pathx)
        //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
        let db = FMDatabase(path: _pathx)
        //let db = NSFileManager.defaultManager().fileExistsAtPath(_pathx)
        
        if db == true {
            print("already create data base")
        }else{
            print("create database")
        }
        
        db.open()
        
        // read data
        let sql2 = "SELECT pic_name, pic_url, pic_date FROM photo_mst order by pic_date;"
        let results = db.executeQuery(sql2, withArgumentsInArray: nil)
        
        
        
        //print(results.next())
        
        if(results.columnCount() > 0){
            //var cnt = 0
            while results.next() {
                //cnt++
                //print(results.stringForColumn("pic_name")+":"+results.stringForColumn("pic_date"))
                //cnt = Int(results.intForColumnIndex(0) as Int32)
                //print(cnt)
            
                let url = NSURL(string: "assets-library://asset/asset.JPG?id=" + results.stringForColumn("pic_name") + "=JPG");
                print("xxxxxassets-library://asset/asset.JPG?id=" + results.stringForColumn("pic_name") + "=JPG")
                var picname = results.stringForColumn("pic_name")
                
                let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithALAssetURLs([url!], options: nil)
                
                
                let asset: PHAsset = fetchResult.firstObject as! PHAsset
                let manager = PHImageManager.defaultManager()
                let assetLib = ALAssetsLibrary()
                assetLib.assetForURL(url, resultBlock: { (asset:ALAsset!) -> Void in
                    
                    //データベースオープン
                    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
                    let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
                    //let db = FMDatabase(path: pathx)
                    //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
                    let db = FMDatabase(path: _pathx)
                    db.open()                    
                    
                    let metadata = asset.defaultRepresentation().metadata()
                    print("metadata")
                    //print(metadata)
                    //self.urlText.text = String(metadata)
                    //self.urlText.text = self.photoAssets[indexPath.row].creationDate as? String
                    
                    
                    if metadata[kCGImagePropertyGPSDictionary] == nil {
                        let sql = "UPDATE photo_mst SET pic_url = :GPS WHERE pic_name = :ID;"
                        print(picname)
                        //self.assetsData.text = "Location data nothing"
                        db.executeUpdate(sql, withParameterDictionary: ["ID":picname, "GPS":"Location data nothing"])
                    }else{
                        let gps = metadata[kCGImagePropertyGPSDictionary] as! [NSObject: AnyObject]
                        let lat = gps[kCGImagePropertyGPSLatitude] as! Double
                        let lng = gps[kCGImagePropertyGPSLongitude] as! Double
                        
                        //NSLog("GPS Info Lat:%f Lng:%f", lat,lng)
                        //self.assetsData.text = "Lat:" + String(lat) + " Log:" + String(lng)
                        let sql = "UPDATE photo_mst SET pic_url = :GPS WHERE pic_name = :ID;"
                        print(picname)
                        
                        db.executeUpdate(sql, withParameterDictionary: ["ID":picname, "GPS":String(lat) + ":" + String(lng)])
                    }
                    
                    //self.dismissViewControllerAnimated(true, completion: nil)
                    
                }) { (error:NSError!) -> Void in
                    
                }
                
                
            }
            //print(cnt)
        }
        
        db.close()
    }
    
    
    func dbupdate(){
        
        //データベースオープン
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)
        let _pathx = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("photolist.db").path
        //let db = FMDatabase(path: pathx)
        //let _pathx = paths[0].stringByAppendingPathComponent("test2.db")
        let db = FMDatabase(path: _pathx)
        //let db = NSFileManager.defaultManager().fileExistsAtPath(_pathx)
        
        if db == true {
            print("already create data base")
        }else{
            print("create database")
        }
        
        db.open()
        let sql3 = "INSERT INTO photo_mst (pic_name,pic_url,pic_path,pic_date,pic_bunrui,pic_comment) VALUES (?, ?, ?, ?, ?, ?);"
        
        //photoAssets = []
        let imgManager = PHImageManager.defaultManager()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        requestOptions.deliveryMode = .HighQualityFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if let fetchResult : PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions){
            
            if fetchResult.count > 0 {
                
                for i in 0..<fetchResult.count{
                    //print(fetchResult.indexOfObject(imgManager))
                    imgManager.requestImageForAsset(fetchResult.objectAtIndex(i) as! PHAsset, targetSize: CGSize(width: 200, height: 200), contentMode: .AspectFill, options: requestOptions, resultHandler:
                        {
                            image, error in
                            
                            //self.imageArray.append(image!)
                            //self.photoAssets.append(fetchResult.objectAtIndex(i) as! PHAsset)
                            let arry = fetchResult.objectAtIndex(i).localIdentifier.componentsSeparatedByString("/L0/001")
                            //self.urlArray.append(arry[0])
                            let date:NSDate? = fetchResult.objectAtIndex(i).creationDate
                            //self.photoUrl.append(PHAsset.defaultRepresentation().url())
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
                            let str:String = dateFormatter.stringFromDate(date!)
                            print(arry[0]+str)
                            //強制的にデータベースへ追加登録
                            db.executeUpdate(sql3, withArgumentsInArray: [arry[0],"test","test",str,"test","test"])
                    })
                    
                    
                    
                }
                
            }
            
        }
        else{
            print("You got no photos!")
            //self.colViewCell.reloadData()
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

