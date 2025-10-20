import React from 'react';
import { ArrowRight, Star, Award, Heart } from 'lucide-react';
import { Button } from './ui/button';
import { siteInfo, heroImages } from '../mock';

const Hero = () => {
  const scrollToSection = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section id="home" className="relative pt-24 pb-16 md:pt-32 md:pb-24 overflow-hidden bg-gradient-to-b from-amber-50 via-orange-50 to-white">
      {/* Decorative Elements */}
      <div className="absolute top-20 right-10 w-72 h-72 bg-orange-200/30 rounded-full blur-3xl"></div>
      <div className="absolute bottom-20 left-10 w-96 h-96 bg-amber-200/20 rounded-full blur-3xl"></div>

      <div className="container mx-auto px-4 relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left Content */}
          <div className="space-y-8">
            {/* Trust Badge */}
            <div className="inline-flex items-center space-x-2 bg-white px-4 py-2 rounded-full shadow-md">
              <Award className="w-5 h-5 text-orange-500" />
              <span className="text-sm font-semibold text-slate-700">Licensed & Certified Care</span>
            </div>

            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-slate-800 leading-tight">
              Where Little Hearts Grow
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-500 to-amber-500">
                {' '}Big Dreams
              </span>
            </h1>

            <p className="text-xl text-slate-600 leading-relaxed">
              Premium childcare services in Sioux City for children 6 weeks to 12 years. 
              Nurturing environment, experienced educators, and programs designed to help your child thrive.
            </p>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-4 py-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-orange-500">15+</div>
                <div className="text-sm text-slate-600 mt-1">Years Experience</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-orange-500">200+</div>
                <div className="text-sm text-slate-600 mt-1">Happy Families</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-orange-500">4.9</div>
                <div className="text-sm text-slate-600 mt-1 flex items-center justify-center space-x-1">
                  <Star className="w-3 h-3 fill-orange-400 text-orange-400" />
                  <span>Rating</span>
                </div>
              </div>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <Button
                onClick={() => scrollToSection('enrollment')}
                className="bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold px-8 py-6 text-lg rounded-full shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105"
              >
                Schedule a Tour
                <ArrowRight className="ml-2 w-5 h-5" />
              </Button>
              <Button
                onClick={() => scrollToSection('programs')}
                variant="outline"
                className="border-2 border-orange-500 text-orange-600 hover:bg-orange-50 font-semibold px-8 py-6 text-lg rounded-full transition-all duration-300"
              >
                View Programs
              </Button>
            </div>

            {/* Trust Indicators */}
            <div className="flex items-center space-x-6 pt-4">
              <div className="flex items-center space-x-2 text-slate-600">
                <Heart className="w-5 h-5 text-red-400" />
                <span className="text-sm">Safe & Secure</span>
              </div>
              <div className="flex items-center space-x-2 text-slate-600">
                <Star className="w-5 h-5 text-amber-400" />
                <span className="text-sm">Top Rated</span>
              </div>
            </div>
          </div>

          {/* Right Images */}
          <div className="relative">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-4">
                <div className="rounded-3xl overflow-hidden shadow-2xl transform hover:scale-105 transition-transform duration-300">
                  <img
                    src={heroImages[0]}
                    alt="Happy children learning"
                    className="w-full h-64 object-cover"
                  />
                </div>
                <div className="rounded-3xl overflow-hidden shadow-2xl transform hover:scale-105 transition-transform duration-300">
                  <img
                    src={heroImages[1]}
                    alt="Children playing"
                    className="w-full h-48 object-cover"
                  />
                </div>
              </div>
              <div className="space-y-4 pt-8">
                <div className="rounded-3xl overflow-hidden shadow-2xl transform hover:scale-105 transition-transform duration-300">
                  <img
                    src={heroImages[2]}
                    alt="Educational activities"
                    className="w-full h-48 object-cover"
                  />
                </div>
                <div className="bg-gradient-to-br from-orange-500 to-amber-500 rounded-3xl p-6 shadow-2xl text-white">
                  <div className="text-4xl font-bold mb-2">Open Now!</div>
                  <div className="text-sm opacity-90">{siteInfo.hours}</div>
                </div>
              </div>
            </div>

            {/* Floating Badge */}
            <div className="absolute -bottom-6 -left-6 bg-white rounded-2xl shadow-xl p-4 transform hover:rotate-3 transition-transform duration-300">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center">
                  <span className="text-2xl">✓</span>
                </div>
                <div>
                  <div className="font-bold text-slate-800">State Licensed</div>
                  <div className="text-xs text-slate-600">Iowa Certified</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;