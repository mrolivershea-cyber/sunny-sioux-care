import React from 'react';
import { MapPin, Mail, Facebook, Instagram, Twitter } from 'lucide-react';
import { siteInfo } from '../mock';

const Footer = () => {
  const scrollToSection = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <footer className="bg-slate-900 text-white pt-16 pb-8">
      <div className="container mx-auto px-4">
        <div className="grid md:grid-cols-4 gap-12 mb-12">
          {/* Brand Section */}
          <div className="space-y-4">
            <div className="flex items-center space-x-2">
              <div className="w-12 h-12 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full flex items-center justify-center">
                <span className="text-2xl">☀️</span>
              </div>
              <div>
                <h3 className="text-xl font-bold">{siteInfo.name}</h3>
                <p className="text-sm text-slate-400">Quality Childcare</p>
              </div>
            </div>
            <p className="text-slate-400 text-sm leading-relaxed">
              Providing nurturing care and education for children in Sioux City since 2008.
            </p>
            {/* Social Links */}
            <div className="flex space-x-3">
              <a
                href="#"
                className="w-10 h-10 bg-slate-800 hover:bg-orange-500 rounded-full flex items-center justify-center transition-colors duration-300"
              >
                <Facebook className="w-5 h-5" />
              </a>
              <a
                href="#"
                className="w-10 h-10 bg-slate-800 hover:bg-orange-500 rounded-full flex items-center justify-center transition-colors duration-300"
              >
                <Instagram className="w-5 h-5" />
              </a>
              <a
                href="#"
                className="w-10 h-10 bg-slate-800 hover:bg-orange-500 rounded-full flex items-center justify-center transition-colors duration-300"
              >
                <Twitter className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-lg font-bold mb-4">Quick Links</h4>
            <ul className="space-y-2">
              <li>
                <button
                  onClick={() => scrollToSection('home')}
                  className="text-slate-400 hover:text-orange-400 transition-colors duration-200"
                >
                  Home
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('programs')}
                  className="text-slate-400 hover:text-orange-400 transition-colors duration-200"
                >
                  Programs
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('about')}
                  className="text-slate-400 hover:text-orange-400 transition-colors duration-200"
                >
                  About Us
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('gallery')}
                  className="text-slate-400 hover:text-orange-400 transition-colors duration-200"
                >
                  Gallery
                </button>
              </li>
              <li>
                <button
                  onClick={() => scrollToSection('contact')}
                  className="text-slate-400 hover:text-orange-400 transition-colors duration-200"
                >
                  Contact
                </button>
              </li>
            </ul>
          </div>

          {/* Programs */}
          <div>
            <h4 className="text-lg font-bold mb-4">Our Programs</h4>
            <ul className="space-y-2 text-slate-400 text-sm">
              <li>• Infant Care (6 weeks - 12 months)</li>
              <li>• Toddler Program (1 - 3 years)</li>
              <li>• Preschool (3 - 5 years)</li>
              <li>• School-Age Care (5 - 12 years)</li>
              <li>• Before & After School</li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h4 className="text-lg font-bold mb-4">Contact Us</h4>
            <ul className="space-y-3">
              <li className="flex items-start space-x-3">
                <MapPin className="w-5 h-5 text-orange-400 flex-shrink-0 mt-1" />
                <span className="text-slate-400 text-sm">
                  {siteInfo.address}<br />
                  {siteInfo.city}, {siteInfo.state} {siteInfo.zip}
                </span>
              </li>
              <li className="flex items-center space-x-3">
                <Phone className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-slate-400 text-sm">{siteInfo.phone}</span>
              </li>
              <li className="flex items-center space-x-3">
                <Mail className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-slate-400 text-sm">{siteInfo.email}</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-slate-800 pt-8 mt-8">
          <div className="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
            <p className="text-slate-400 text-sm text-center md:text-left">
              © 2025 {siteInfo.name}. All rights reserved.
            </p>
            <div className="flex space-x-6 text-sm">
              <a href="#" className="text-slate-400 hover:text-orange-400 transition-colors">
                Privacy Policy
              </a>
              <a href="#" className="text-slate-400 hover:text-orange-400 transition-colors">
                Terms of Service
              </a>
              <a href="#" className="text-slate-400 hover:text-orange-400 transition-colors">
                Licensing
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
