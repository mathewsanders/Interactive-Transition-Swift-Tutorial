//
//  MenuTransitionManager.swift
//  Menu
//
//  Created by Mathew Sanders on 9/7/14.
//  Copyright (c) 2014 Mat. All rights reserved.
//

import UIKit

class MenuTransitionManager: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning {
    
    private var presenting = false
    private var interactive = false

    private var enterPanGesture: UIScreenEdgePanGestureRecognizer!
    
    var sourceViewController: UIViewController! {
        didSet {
            self.enterPanGesture = UIScreenEdgePanGestureRecognizer()
            self.enterPanGesture.addTarget(self, action:"handleOnstagePan:")
            self.enterPanGesture.edges = UIRectEdge.Left
            self.sourceViewController.view.addGestureRecognizer(self.enterPanGesture)
        }
    }
    
    private var exitPanGesture: UIPanGestureRecognizer!
    
    var menuViewController: UIViewController! {
        didSet {
            self.exitPanGesture = UIPanGestureRecognizer()
            self.exitPanGesture.addTarget(self, action:"handleOffstagePan:")
            self.menuViewController.view.addGestureRecognizer(self.exitPanGesture)
        }
    }
    
    func handleOnstagePan(pan: UIPanGestureRecognizer){
        // how much distance have we panned in reference to the parent view?
        let translation = pan.translationInView(pan.view!)
        
        // do some math to translate this to a percentage based value
        let d =  translation.x / CGRectGetWidth(pan.view!.bounds) * 0.5
        
        // now lets deal with different states that the gesture recognizer sends
        switch (pan.state) {
            
        case UIGestureRecognizerState.Began:
            // set our interactive flag to true
            self.interactive = true
            
            // trigger the start of the transition
            self.sourceViewController.performSegueWithIdentifier("presentMenu", sender: self)
            break
            
        case UIGestureRecognizerState.Changed:
            
            // update progress of the transition
            self.updateInteractiveTransition(d)
            break
            
        default: // .Ended, .Cancelled, .Failed ...
            
            // return flag to false and finish the transition
            self.interactive = false
            if(d > 0.2){
                // threshold crossed: finish
                self.finishInteractiveTransition()
            }
            else {
                // threshold not met: cancel
                self.cancelInteractiveTransition()
            }
        }
    }
    
    // pretty much the same as 'handleOnstagePan' except 
    // we're panning from right to left
    // perfoming our exitSegeue to start the transition
    func handleOffstagePan(pan: UIPanGestureRecognizer){
        
        let translation = pan.translationInView(pan.view!)
        let d =  translation.x / CGRectGetWidth(pan.view!.bounds) * -0.5
        
        switch (pan.state) {
            
        case UIGestureRecognizerState.Began:
            self.interactive = true
            self.menuViewController.performSegueWithIdentifier("dismissMenu", sender: self)
            break
            
        case UIGestureRecognizerState.Changed:
            self.updateInteractiveTransition(d)
            break
            
        default: // .Ended, .Cancelled, .Failed ...
            self.interactive = false
            if(d > 0.1){
                self.finishInteractiveTransition()
            }
            else {
                self.cancelInteractiveTransition()
            }
        }
    }
    
    // MARK: UIViewControllerAnimatedTransitioning protocol methods
    
    // animate a change from one viewcontroller to another
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView()
        
        // create a tuple of our screens
        let screens : (from:UIViewController, to:UIViewController) = (transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!, transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!)
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let menuViewController = !self.presenting ? screens.from as MenuViewController : screens.to as MenuViewController
        let bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController
        
        let menuView = menuViewController.view
        let bottomView = bottomViewController.view
        
        // prepare menu items to slide in
        if (self.presenting){
            if(self.interactive){
                self.offStageMenuControllerInteractive(menuViewController) // offstage for interactive
            }else{
                self.offStageMenuController(menuViewController) // offstage for default
            }
        }
        
        // add the both views to our view controller
        container.addSubview(bottomView)
        container.addSubview(menuView)
        
        let duration = self.transitionDuration(transitionContext)
        
        // perform the animation!
        UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: nil, animations: {
            
                if (self.presenting){
                    self.onStageMenuController(menuViewController) // onstage items: slide in
                }
                else {
                    if(self.interactive){
                        self.offStageMenuControllerInteractive(menuViewController) // offstage for interactive
                    }else{
                        self.offStageMenuController(menuViewController) // offstage for default
                    }
                    
                }

            }, completion: { finished in
                
                // tell our transitionContext object that we've finished animating
                if(transitionContext.transitionWasCancelled()){
                    
                    transitionContext.completeTransition(false)
                    // bug: we have to manually add our 'to view' back http://openradar.appspot.com/radar?id=5320103646199808
                    UIApplication.sharedApplication().keyWindow.addSubview(screens.from.view)
                    
                }
                else {
                    
                    transitionContext.completeTransition(true)
                    // bug: we have to manually add our 'to view' back http://openradar.appspot.com/radar?id=5320103646199808
                    UIApplication.sharedApplication().keyWindow.addSubview(screens.to.view)
                    
                }
                
        })
        
    }
    
    func offStage(amount: CGFloat) -> CGAffineTransform {
        return CGAffineTransformMakeTranslation(amount, 0)
    }
    
    func offStageMenuController(menuViewController: MenuViewController){
        
        menuViewController.view.alpha = 0
        
        // setup paramaters for 2D transitions for animations
        let topRowOffset  :CGFloat = 300
        let middleRowOffset :CGFloat = 150
        let bottomRowOffset  :CGFloat = 50
        
        menuViewController.textPostIcon.transform = self.offStage(-topRowOffset)
        menuViewController.textPostLabel.transform = self.offStage(-topRowOffset)
        
        menuViewController.quotePostIcon.transform = self.offStage(-middleRowOffset)
        menuViewController.quotePostLabel.transform = self.offStage(-middleRowOffset)
        
        menuViewController.chatPostIcon.transform = self.offStage(-bottomRowOffset)
        menuViewController.chatPostLabel.transform = self.offStage(-bottomRowOffset)
        
        menuViewController.photoPostIcon.transform = self.offStage(topRowOffset)
        menuViewController.photoPostLabel.transform = self.offStage(topRowOffset)
        
        menuViewController.linkPostIcon.transform = self.offStage(middleRowOffset)
        menuViewController.linkPostLabel.transform = self.offStage(middleRowOffset)
        
        menuViewController.audioPostIcon.transform = self.offStage(bottomRowOffset)
        menuViewController.audioPostLabel.transform = self.offStage(bottomRowOffset)
        
    }
    
    func offStageMenuControllerInteractive(menuViewController: MenuViewController){
        
        menuViewController.view.alpha = 0
        
        // setup paramaters for 2D transitions for animations
        let offstageOffset  :CGFloat = -300
        
        menuViewController.textPostIcon.transform = self.offStage(offstageOffset)
        menuViewController.textPostLabel.transform = self.offStage(offstageOffset)
        
        menuViewController.quotePostIcon.transform = self.offStage(offstageOffset)
        menuViewController.quotePostLabel.transform = self.offStage(offstageOffset)
        
        menuViewController.chatPostIcon.transform = self.offStage(offstageOffset)
        menuViewController.chatPostLabel.transform = self.offStage(offstageOffset)
        
        menuViewController.photoPostIcon.transform = self.offStage(offstageOffset)
        menuViewController.photoPostLabel.transform = self.offStage(offstageOffset)
        
        menuViewController.linkPostIcon.transform = self.offStage(offstageOffset)
        menuViewController.linkPostLabel.transform = self.offStage(offstageOffset)
        
        menuViewController.audioPostIcon.transform = self.offStage(offstageOffset)
        menuViewController.audioPostLabel.transform = self.offStage(offstageOffset)
        
    }
    
    func onStageMenuController(menuViewController: MenuViewController){
        
        // prepare menu to fade in
        menuViewController.view.alpha = 1
        
        menuViewController.textPostIcon.transform = CGAffineTransformIdentity
        menuViewController.textPostLabel.transform = CGAffineTransformIdentity
        
        menuViewController.quotePostIcon.transform = CGAffineTransformIdentity
        menuViewController.quotePostLabel.transform = CGAffineTransformIdentity
        
        menuViewController.chatPostIcon.transform = CGAffineTransformIdentity
        menuViewController.chatPostLabel.transform = CGAffineTransformIdentity
        
        menuViewController.photoPostIcon.transform = CGAffineTransformIdentity
        menuViewController.photoPostLabel.transform = CGAffineTransformIdentity
        
        menuViewController.linkPostIcon.transform = CGAffineTransformIdentity
        menuViewController.linkPostLabel.transform = CGAffineTransformIdentity
        
        menuViewController.audioPostIcon.transform = CGAffineTransformIdentity
        menuViewController.audioPostLabel.transform = CGAffineTransformIdentity
        
    }
    
    // return how many seconds the transiton animation will take
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.5
    }
    
    // MARK: UIViewControllerTransitioningDelegate protocol methods
    
    // return the animataor when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if our interactive flag is true, return the transition manager object
        // otherwise return nil
        return self.interactive ? self : nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactive ? self : nil
    }
    
}
