import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Menu, X, Phone, Mail } from 'lucide-react';
import { siteInfo } from '../mock';
import { Button } from './ui/button';

const Header = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollToSection = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setIsMobileMenuOpen(false);
    }
  };

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? 'bg-white shadow-md py-3' : 'bg-white/95 backdrop-blur-sm py-4'
      }`}
    >
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2 group">
            <div className="w-12 h-12 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full flex items-center justify-center transform group-hover:scale-110 transition-transform duration-300">
              <span className="text-2xl">☀️</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold text-slate-800 leading-tight">
                {siteInfo.name}
              </span>
              <span className="text-xs text-slate-600">{siteInfo.city}, {siteInfo.state}</span>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-8">
            <button
              onClick={() => scrollToSection('home')}
              className="text-slate-700 hover:text-orange-500 font-medium transition-colors duration-200"
            >
              Home
            </button>
            <button
              onClick={() => scrollToSection('programs')}
              className="text-slate-700 hover:text-orange-500 font-medium transition-colors duration-200"
            >
              Programs
            </button>
            <button
              onClick={() => scrollToSection('about')}
              className="text-slate-700 hover:text-orange-500 font-medium transition-colors duration-200"
            >
              About
            </button>
            <button
              onClick={() => scrollToSection('gallery')}
              className="text-slate-700 hover:text-orange-500 font-medium transition-colors duration-200"
            >
              Gallery
            </button>
            <button
              onClick={() => scrollToSection('contact')}
              className="text-slate-700 hover:text-orange-500 font-medium transition-colors duration-200"
            >
              Contact
            </button>
          </nav>

          {/* Contact Info & CTA */}
          <div className="hidden lg:flex items-center space-x-4">
            <Button
              onClick={() => scrollToSection('enrollment')}
              className="bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-semibold px-6 py-2 rounded-full shadow-lg hover:shadow-xl transition-all duration-300"
            >
              Enroll Now
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="md:hidden p-2 text-slate-700 hover:text-orange-500 transition-colors"
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="md:hidden mt-4 pb-4 border-t border-slate-200 pt-4">
            <nav className="flex flex-col space-y-3">
              <button
                onClick={() => scrollToSection('home')}
                className="text-slate-700 hover:text-orange-500 font-medium text-left py-2 transition-colors"
              >
                Home
              </button>
              <button
                onClick={() => scrollToSection('programs')}
                className="text-slate-700 hover:text-orange-500 font-medium text-left py-2 transition-colors"
              >
                Programs
              </button>
              <button
                onClick={() => scrollToSection('about')}
                className="text-slate-700 hover:text-orange-500 font-medium text-left py-2 transition-colors"
              >
                About
              </button>
              <button
                onClick={() => scrollToSection('gallery')}
                className="text-slate-700 hover:text-orange-500 font-medium text-left py-2 transition-colors"
              >
                Gallery
              </button>
              <button
                onClick={() => scrollToSection('contact')}
                className="text-slate-700 hover:text-orange-500 font-medium text-left py-2 transition-colors"
              >
                Contact
              </button>
              <Button
                onClick={() => scrollToSection('enrollment')}
                className="bg-gradient-to-r from-orange-500 to-amber-500 text-white font-semibold py-2 rounded-full"
              >
                Enroll Now
              </Button>
            </nav>
          </div>
        )}
      </div>
    </header>
  );
};

export default Header;