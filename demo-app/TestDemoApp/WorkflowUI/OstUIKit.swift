//
//  OstUIKit.swift
//  TestDemoApp
//
//  Created by Rachin Kapoor on 26/04/19.
//  Copyright © 2019 aniket ayachit. All rights reserved.
//

import UIKit
import MaterialComponents.MDCTextField

class OstUIKit {
    class func primaryButton() -> UIButton {
        let view = UIButton();
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let themer = OstTheme.primaryButton;
        themer.apply(view);
        return view;
    }
    
    class func secondaryButton() -> UIButton {
        let view = UIButton();
        view.translatesAutoresizingMaskIntoConstraints = false
        let themer = OstTheme.secondaryButton;
        themer.apply(view);
        return view;
    }
    
    class func h1() -> UILabel {
        let view = UILabel();
        view.translatesAutoresizingMaskIntoConstraints = false
        let themer = OstTheme.h1;
        themer.apply(view);
        return view;
    }
    
    class func leadLabel() -> UILabel {
        let view = UILabel();
        view.translatesAutoresizingMaskIntoConstraints = false
        let themer = OstTheme.leadLabel;
        themer.apply(view);
        return view;
    }
    
    class func textField() -> MDCTextField {
        let view = MDCTextField();
        view.translatesAutoresizingMaskIntoConstraints = false
        return view;
    }
}
