//
//  MyCollectionViewCell.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-27.
//

import UIKit
import PDFKit

class MyCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    static let identifier = "MyCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func configure(with url: URL) {
        imageView.image = pdfThumbnail(url: url)
    }
    
    func pdfThumbnail(url: URL, width: CGFloat = 240) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
        let page = PDFDocument(data: data)?.page(at: 0) else {
        return nil
        }

        let pageSize = page.bounds(for: .mediaBox)
        let pdfScale = width / pageSize.width
        let scale = UIScreen.main.scale * pdfScale
        let screenSize = CGSize(width: pageSize.width * scale,
                              height: pageSize.height * scale)

        return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "MyCollectionViewCell", bundle: nil)
    }

}
