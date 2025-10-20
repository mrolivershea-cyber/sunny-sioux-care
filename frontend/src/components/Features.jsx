import React from 'react';
import { Shield, UtensilsCrossed, GraduationCap, Trees, BookOpen, Clock } from 'lucide-react';
import { features } from '../mock';

const iconMap = {
  Shield: Shield,
  UtensilsCrossed: UtensilsCrossed,
  GraduationCap: GraduationCap,
  Trees: Trees,
  BookOpen: BookOpen,
  Clock: Clock
};

const Features = () => {
  return (
    <section id="about" className="py-20 bg-gradient-to-b from-white to-amber-50">
      <div className="container mx-auto px-4">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-4">
          <h2 className="text-4xl md:text-5xl font-bold text-slate-800">
            Why Parents Choose Us
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            We're committed to providing the highest quality care in a nurturing, safe, and stimulating environment.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {features.map((feature, index) => {
            const IconComponent = iconMap[feature.icon];
            return (
              <div
                key={feature.id}
                className="group bg-white rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2 border border-slate-100"
              >
                <div className="flex flex-col items-center text-center space-y-4">
                  <div className="w-16 h-16 bg-gradient-to-br from-orange-400 to-amber-500 rounded-2xl flex items-center justify-center transform group-hover:scale-110 group-hover:rotate-6 transition-transform duration-300 shadow-lg">
                    <IconComponent className="w-8 h-8 text-white" />
                  </div>
                  <h3 className="text-xl font-bold text-slate-800">{feature.title}</h3>
                  <p className="text-slate-600 leading-relaxed">{feature.description}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default Features;