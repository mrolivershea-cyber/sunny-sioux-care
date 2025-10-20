import React from 'react';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from './ui/accordion';
import { faqs } from '../mock';
import { Badge } from './ui/badge';

const FAQ = () => {
  return (
    <section className="py-20 bg-white">
      <div className="container mx-auto px-4">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-4">
          <Badge className="bg-orange-100 text-orange-600 hover:bg-orange-100 px-4 py-1 text-sm font-semibold">
            FAQ
          </Badge>
          <h2 className="text-4xl md:text-5xl font-bold text-slate-800">
            Frequently Asked Questions
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            Have questions? We've got answers. If you don't find what you're looking for, feel free to contact us!
          </p>
        </div>

        {/* FAQ Accordion */}
        <div className="max-w-4xl mx-auto">
          <Accordion type="single" collapsible className="space-y-4">
            {faqs.map((faq) => (
              <AccordionItem
                key={faq.id}
                value={`item-${faq.id}`}
                className="bg-amber-50 rounded-xl px-6 border-2 border-transparent hover:border-orange-300 transition-all duration-300"
              >
                <AccordionTrigger className="text-left font-semibold text-slate-800 hover:text-orange-600 py-6">
                  {faq.question}
                </AccordionTrigger>
                <AccordionContent className="text-slate-600 leading-relaxed pb-6">
                  {faq.answer}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </div>
    </section>
  );
};

export default FAQ;