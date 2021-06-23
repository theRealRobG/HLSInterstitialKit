//
//  HomePageViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 23/06/2021.
//

import UIKit

class HomePageViewController: UIPageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        setViewControllers(
            [getStartInterstitialViewController(id: .interstitialKit)],
            direction: .forward,
            animated: true,
            completion: nil
        )
    }
    
    private func getStartInterstitialViewController(id: StartInterstitialViewControllerIdentifier) -> UIViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: id.rawValue)
    }
}

extension HomePageViewController {
    enum StartInterstitialViewControllerIdentifier: String {
        case interstitialKit = "InterstitialKitViewController"
        case avFoundation = "AVInterstitialViewController"
    }
}

extension HomePageViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if #available(iOS 15, tvOS 15, *) {
            guard viewController is AVInterstitialViewController else { return nil }
            return getStartInterstitialViewController(id: .interstitialKit)
        }
        return nil
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if #available(iOS 15, tvOS 15, *) {
            guard viewController is InterstitialKitViewController else { return nil }
            return getStartInterstitialViewController(id: .avFoundation)
        }
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        if #available(iOS 15, tvOS 15, *) {
            return 2
        } else {
            return 1
        }
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        pageViewController.viewControllers?.first.map { $0 is InterstitialKitViewController ? 0 : 1 } ?? 0
    }
}
