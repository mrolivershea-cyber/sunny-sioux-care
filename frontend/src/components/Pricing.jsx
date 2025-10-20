import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { Badge } from './ui/badge';
import { Check, DollarSign, Send, ExternalLink } from 'lucide-react';
import { pricingPlans } from '../mock';
import { toast } from 'sonner';
import axios from 'axios';

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const Pricing = () => {
  const [showInvoiceForm, setShowInvoiceForm] = useState(false);
  const [formData, setFormData] = useState({
    customerEmail: '',
    description: '',
    amount: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [invoiceUrl, setInvoiceUrl] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.customerEmail || !formData.description || !formData.amount) {
      toast.error('Please fill in all fields');
      return;
    }

    if (isNaN(formData.amount) || parseFloat(formData.amount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    setIsSubmitting(true);
    setInvoiceUrl('');

    try {
      const response = await axios.post(`${API}/create-invoice`, {
        customerEmail: formData.customerEmail,
        description: formData.description,
        amount: parseFloat(formData.amount)
      });

      if (response.data.success) {
        toast.success(response.data.message);
        setInvoiceUrl(response.data.invoiceUrl);
        setFormData({
          customerEmail: '',
          description: '',
          amount: ''
        });
      }
    } catch (error) {
      console.error('Invoice creation error:', error);
      const errorMsg = error.response?.data?.detail || 'Failed to create invoice. Please try again.';
      toast.error(errorMsg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section id="pricing" className="py-20 bg-gradient-to-b from-white to-amber-50">
      <div className="container mx-auto px-4">
        {/* Section Header */}
        <div className="text-center mb-16 space-y-4">
          <Badge className="bg-orange-100 text-orange-600 hover:bg-orange-100 px-4 py-1 text-sm font-semibold">
            Pricing Plans
          </Badge>
          <h2 className="text-4xl md:text-5xl font-bold text-slate-800">
            Affordable Quality Care
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            Choose the plan that fits your family's needs. All plans include meals, activities, and loving care.
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto mb-12">
          {pricingPlans.map((plan) => (
            <Card
              key={plan.id}
              className={`relative overflow-hidden transition-all duration-300 transform hover:-translate-y-2 ${
                plan.popular
                  ? 'border-4 border-orange-400 shadow-2xl'
                  : 'border-2 hover:border-orange-300 shadow-lg hover:shadow-xl'
              }`}
            >
              {plan.popular && (
                <div className="absolute top-0 right-0 bg-gradient-to-r from-orange-500 to-amber-500 text-white px-4 py-1 text-sm font-bold rounded-bl-lg">
                  MOST POPULAR
                </div>
              )}

              <CardHeader className="text-center space-y-4 pt-8">
                <Badge className="mx-auto bg-amber-100 text-amber-700 hover:bg-amber-100">
                  {plan.age}
                </Badge>
                <CardTitle className="text-2xl font-bold text-slate-800">
                  {plan.name}
                </CardTitle>
                <CardDescription className="text-slate-600">
                  {plan.description}
                </CardDescription>
                <div className="pt-4">
                  <div className="flex items-baseline justify-center">
                    <span className="text-5xl font-bold text-orange-500">
                      ${plan.price}
                    </span>
                    <span className="text-slate-600 ml-2">/{plan.period}</span>
                  </div>
                </div>
              </CardHeader>

              <CardContent className="space-y-6">
                <div className="space-y-3">
                  {plan.features.map((feature, idx) => (
                    <div key={idx} className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-sm text-slate-700">{feature}</span>
                    </div>
                  ))}
                </div>

                <Button
                  onClick={() => {
                    const element = document.getElementById('contact');
                    if (element) element.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className={`w-full py-6 text-lg font-bold rounded-xl transition-all duration-300 ${
                    plan.popular
                      ? 'bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white shadow-lg hover:shadow-xl'
                      : 'bg-white border-2 border-orange-500 text-orange-600 hover:bg-orange-50'
                  }`}
                >
                  Get Started
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Custom Invoice Section */}
        <div className="max-w-2xl mx-auto mt-16">
          <Card className="border-2 border-orange-200 shadow-xl">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-amber-50 text-center">
              <div className="w-16 h-16 bg-gradient-to-br from-orange-500 to-amber-500 rounded-full flex items-center justify-center mx-auto mb-4">
                <DollarSign className="w-8 h-8 text-white" />
              </div>
              <CardTitle className="text-2xl font-bold text-slate-800">
                Need a Custom Payment?
              </CardTitle>
              <CardDescription className="text-slate-600">
                Request an invoice for registration fees, deposits, or custom services
              </CardDescription>
            </CardHeader>

            <CardContent className="p-6">
              {!showInvoiceForm ? (
                <Button
                  onClick={() => setShowInvoiceForm(true)}
                  className="w-full h-12 bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold rounded-xl"
                >
                  Request Custom Invoice
                </Button>
              ) : (
                <>
                  {invoiceUrl && (
                    <div className="mb-6 p-4 bg-green-50 border-2 border-green-200 rounded-lg">
                      <p className="text-green-800 font-semibold mb-3">✓ Invoice created successfully!</p>
                      <a
                        href={invoiceUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors duration-200"
                      >
                        <ExternalLink className="w-4 h-4 mr-2" />
                        Open Invoice to Pay
                      </a>
                    </div>
                  )}

                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="space-y-2">
                      <label htmlFor="customerEmail" className="text-sm font-semibold text-slate-700">
                        Your Email *
                      </label>
                      <Input
                        id="customerEmail"
                        name="customerEmail"
                        type="email"
                        placeholder="your.email@example.com"
                        value={formData.customerEmail}
                        onChange={handleChange}
                        className="h-11 border-2 focus:border-orange-500"
                        required
                        disabled={isSubmitting}
                      />
                    </div>

                    <div className="space-y-2">
                      <label htmlFor="description" className="text-sm font-semibold text-slate-700">
                        Service Description *
                      </label>
                      <Textarea
                        id="description"
                        name="description"
                        placeholder="e.g., Registration fee, Monthly tuition..."
                        value={formData.description}
                        onChange={handleChange}
                        className="min-h-24 border-2 focus:border-orange-500"
                        required
                        disabled={isSubmitting}
                      />
                    </div>

                    <div className="space-y-2">
                      <label htmlFor="amount" className="text-sm font-semibold text-slate-700">
                        Amount (USD) *
                      </label>
                      <div className="relative">
                        <span className="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-500 font-semibold">
                          $
                        </span>
                        <Input
                          id="amount"
                          name="amount"
                          type="number"
                          step="0.01"
                          min="0"
                          placeholder="0.00"
                          value={formData.amount}
                          onChange={handleChange}
                          className="h-11 pl-8 border-2 focus:border-orange-500"
                          required
                          disabled={isSubmitting}
                        />
                      </div>
                    </div>

                    <div className="flex space-x-3">
                      <Button
                        type="button"
                        onClick={() => {
                          setShowInvoiceForm(false);
                          setFormData({ customerEmail: '', description: '', amount: '' });
                          setInvoiceUrl('');
                        }}
                        variant="outline"
                        className="flex-1 h-11 border-2 border-slate-300"
                        disabled={isSubmitting}
                      >
                        Cancel
                      </Button>
                      <Button
                        type="submit"
                        disabled={isSubmitting}
                        className="flex-1 h-11 bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold rounded-lg"
                      >
                        {isSubmitting ? (
                          <>
                            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                            Creating...
                          </>
                        ) : (
                          <>
                            <Send className="w-4 h-4 mr-2" />
                            Create Invoice
                          </>
                        )}
                      </Button>
                    </div>
                  </form>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
};

export default Pricing;