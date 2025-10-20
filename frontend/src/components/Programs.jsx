import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { programs } from '../mock';
import { Check } from 'lucide-react';

const Programs = () => {
  return (
    <section id="programs" className="py-20 bg-white">
      <div className="container mx-auto px-4">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-4">
          <Badge className="bg-orange-100 text-orange-600 hover:bg-orange-100 px-4 py-1 text-sm font-semibold">
            Our Programs
          </Badge>
          <h2 className="text-4xl md:text-5xl font-bold text-slate-800">
            Age-Appropriate Programs for Every Stage
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            From infants to school-age children, we provide specialized care and education tailored to each developmental stage.
          </p>
        </div>

        {/* Programs Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {programs.map((program, index) => (
            <Card
              key={program.id}
              className="group hover:shadow-2xl transition-all duration-300 border-2 hover:border-orange-300 overflow-hidden transform hover:-translate-y-2"
            >
              {/* Image */}
              <div className="relative h-48 overflow-hidden">
                <img
                  src={program.image}
                  alt={program.title}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                <Badge className="absolute top-4 right-4 bg-white text-slate-800 font-semibold">
                  {program.age}
                </Badge>
              </div>

              <CardHeader className="space-y-2">
                <CardTitle className="text-2xl text-slate-800 group-hover:text-orange-500 transition-colors">
                  {program.title}
                </CardTitle>
                <CardDescription className="text-slate-600 leading-relaxed">
                  {program.description}
                </CardDescription>
              </CardHeader>

              <CardContent>
                <div className="space-y-2">
                  {program.features.map((feature, idx) => (
                    <div key={idx} className="flex items-start space-x-2">
                      <Check className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-sm text-slate-700">{feature}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Programs;