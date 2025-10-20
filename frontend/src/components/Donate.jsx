import React, { useEffect, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Heart } from 'lucide-react';

const Donate = () => {
  const buttonRendered = useRef(false);
  const scriptLoaded = useRef(false);

  useEffect(() => {
    // Check if button already rendered
    if (buttonRendered.current) return;
    
    // Check if script already loaded
    if (scriptLoaded.current || window.PayPal?.Donation) {
      // Script already loaded, just render button
      if (window.PayPal && window.PayPal.Donation && !buttonRendered.current) {
        try {
          window.PayPal.Donation.Button({
            env: 'production',
            hosted_button_id: 'B6XLRY6MY435A',
            image: {
              src: 'https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif',
              alt: 'Donate with PayPal button',
              title: 'PayPal - The safer, easier way to pay online!',
            }
          }).render('#donate-button');
          buttonRendered.current = true;
        } catch (error) {
          console.log('PayPal button already rendered');
        }
      }
      return;
    }
    
    // Load PayPal Donate SDK for first time
    const script = document.createElement('script');
    script.src = 'https://www.paypalobjects.com/donate/sdk/donate-sdk.js';
    script.charset = 'UTF-8';
    script.async = true;
    
    script.onload = () => {
      scriptLoaded.current = true;
      if (window.PayPal && window.PayPal.Donation && !buttonRendered.current) {
        try {
          window.PayPal.Donation.Button({
            env: 'production',
            hosted_button_id: 'B6XLRY6MY435A',
            image: {
              src: 'https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif',
              alt: 'Donate with PayPal button',
              title: 'PayPal - The safer, easier way to pay online!',
            }
          }).render('#donate-button');
          buttonRendered.current = true;
        } catch (error) {
          console.log('PayPal button render error:', error.message);
        }
      }
    };
    
    // Only add script if not already present
    const existingScript = document.querySelector('script[src*="paypalobjects.com/donate"]');
    if (!existingScript) {
      document.body.appendChild(script);
    }
    
    return () => {
      // Cleanup only if component truly unmounts
      // Don't remove script as it might be needed by other instances
    };
  }, []);

  return (
    <section className="py-16 bg-gradient-to-b from-amber-50 to-white">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto">
          <Card className="border-2 border-orange-200 shadow-xl overflow-hidden">
            <CardHeader className="text-center space-y-4 bg-gradient-to-r from-orange-50 to-amber-50 py-8">
              <div className="w-20 h-20 bg-gradient-to-br from-red-400 to-pink-500 rounded-full flex items-center justify-center mx-auto">
                <Heart className="w-10 h-10 text-white fill-white" />
              </div>
              <CardTitle className="text-4xl font-bold text-slate-800">
                Support Our Mission
              </CardTitle>
              <CardDescription className="text-lg text-slate-600 max-w-2xl mx-auto">
                Happy with our care? Your donation helps us provide quality childcare to more families in our community.
              </CardDescription>
            </CardHeader>

            <CardContent className="p-12">
              <div className="text-center space-y-8">
                <p className="text-slate-700 leading-relaxed text-lg">
                  Every contribution makes a difference in the lives of children and families we serve. 
                  Your support helps us maintain facilities, purchase educational materials, and continue providing 
                  exceptional care.
                </p>
                
                {/* PayPal Donate Button Container - Single Button */}
                <div className="flex justify-center py-6">
                  <div id="donate-button"></div>
                </div>

                <p className="text-sm text-slate-500 pt-4">
                  Secure payment processed through PayPal. Thank you for your generosity! ❤️
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
};

export default Donate;