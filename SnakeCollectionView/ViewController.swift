//
//  ViewController.swift
//  SnakeCollectionView
//
//  Created by Nikhil Gohil on 02/06/2019.
//  Copyright © 2019 Nikhil Gohil. All rights reserved.
//

import UIKit
import Foundation

class ChainedAnimationsQueue {
    
    private var playing = false
    private var animations = [(TimeInterval, () -> Void, () -> Void)]()
    
    init() {
    }
    
    /// Queue the animated changes to one or more views using the specified duration and an initialization block.
    ///
    /// - Parameters:
    ///   - duration: The total duration of the animations, measured in seconds. If you specify a negative value or 0, the changes are made without animating them.
    ///   - initializations: A block object containing the changes to commit to the views to set their initial state. This block takes no parameters and has no return value. This parameter must not be NULL.
    ///   - animations: A block object containing the changes to commit to the views. This is where you programmatically change any animatable properties of the views in your view hierarchy. This block takes no parameters and has no return value. This parameter must not be NULL.
    func queue(withDuration duration: TimeInterval, initializations: @escaping () -> Void, animations: @escaping () -> Void) {
        self.animations.append((duration, initializations, animations))
        if !playing {
            playing = true
            DispatchQueue.main.async {
                self.next()
            }
        }
    }
    
    private func next() {
        if animations.count > 0 {
            let animation = animations.removeFirst()
            animation.1()
            UIView.animate(withDuration: animation.0, animations: animation.2, completion: { finished in
                self.next()
            })
        } else {
            playing = false
        }
    }
}

class ViewController: UIViewController {
    var animationsQueue = ChainedAnimationsQueue()
    var animatedIndexes : [Int] = [Int]()
    var cellWidth = 100
    fileprivate lazy var collectionView: UICollectionView = { [unowned self] in
        $0.dataSource = self
        $0.delegate = self
        $0.register(TypeOneCell.self, forCellWithReuseIdentifier: TypeOneCell.identifier)
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.decelerationRate = UIScrollView.DecelerationRate.fast
        $0.bounces = true
        $0.backgroundColor = .white
        $0.contentInset.bottom = 50
        return $0
        }(UICollectionView(frame: .zero, collectionViewLayout: layout))
    
    fileprivate lazy var layout: VerticalScrollFlowLayout = {
        return $0
    }(VerticalScrollFlowLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let flowLayout = VerticalScrollFlowLayout()
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.collectionViewWidth = self.view.frame.size.width
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = CGSize(width: (self.view.frame.size.width/3)-1, height: 99)
        self.collectionView.collectionViewLayout = flowLayout
        
    }
    
    override func viewDidLayoutSubviews() {
        self.collectionView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
    }
}

extension ViewController : UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = collectionView.dequeueReusableCell(withReuseIdentifier: TypeOneCell.identifier, for: indexPath) as? TypeOneCell else { return UICollectionViewCell() }
        item.title.text = "\(indexPath.item)"
        item.alpha = 0.0
        return item
    }
}

extension ViewController : UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0.0
        cell.backgroundColor = .white
        if !animatedIndexes.contains(indexPath.item){
            self.animatedIndexes.append(indexPath.item)
            animationsQueue.queue(withDuration: 0.5, initializations: {
                cell.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, cell.frame.size.height, 0)
            }, animations: {
                cell.alpha = 1.0
                cell.backgroundColor = .red
                cell.layer.transform = CATransform3DIdentity
            })
        }else{
            cell.alpha = 1.0
        }
    }
}

class TypeOneCell: UICollectionViewCell {
    
    static let identifier = String(describing: TypeOneCell.self)
    
    public lazy var title: UILabel = {
        $0.textColor = .black
        $0.numberOfLines = 1
        $0.textAlignment = .center
        return $0
    }(UILabel())
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        backgroundColor = .white
        self.contentView.addSubview(title)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        //Log("layoutMargins = \(layoutMargins), contentView = \(contentView.bounds)")
        layout()
    }
    
    func layout() {
        title.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: self.contentView.frame.size.width-20, height: self.contentView.frame.size.height-20))
        style(view: title)
    }
    
    func style(view: UIView) {
        view.clipsToBounds = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 14
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 1, height: 5)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.2
        view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 14, height: 14)).cgPath
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
    }
}

//
class VerticalScrollFlowLayout: UICollectionViewFlowLayout {
    var collectionViewWidth : CGFloat?
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let currentItemAttributes : UICollectionViewLayoutAttributes = super.layoutAttributesForItem(at: indexPath)!
        let width : CGFloat = self.collectionViewWidth ?? 300
        var frame : CGRect = currentItemAttributes.frame;
        let column : Double = Double(indexPath.item/3)
        if (column.remainder(dividingBy: 2) == 0) {
            frame.origin.x = width - (frame.size.width+frame.origin.x)
        }
        currentItemAttributes.frame = frame;
        return currentItemAttributes;
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let originalAttributes =
            super.layoutAttributesForElements(in: rect)
        var updatedAttributes : [UICollectionViewLayoutAttributes] = originalAttributes!
        for attributes in originalAttributes! {
            if !(attributes.representedElementKind != nil) {
                let index = updatedAttributes.firstIndex(of: attributes)
                updatedAttributes[index!] = self.layoutAttributesForItem(at: attributes.indexPath)!
            }
        }
        return updatedAttributes;
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
