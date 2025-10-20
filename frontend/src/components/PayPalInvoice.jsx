import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { toast } from 'sonner';
import { DollarSign, Send, CheckCircle } from 'lucide-react';

const PayPalInvoice = () => {
  const [formData, setFormData] = useState({
    customerEmail: '',
    description: '',
    amount: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validation
    if (!formData.customerEmail || !formData.description || !formData.amount) {
      toast.error('Please fill in all fields');
      return;
    }

    if (isNaN(formData.amount) || parseFloat(formData.amount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    setIsSubmitting(true);

    // Mock invoice creation (will be replaced with actual PayPal API call)
    setTimeout(() => {
      toast.success('Invoice created! Check your email for payment link.');
      setFormData({
        customerEmail: '',
        description: '',
        amount: ''
      });
      setIsSubmitting(false);
    }, 1500);
  };

  return (
    <section id="enrollment" className="py-20 bg-gradient-to-b from-white to-amber-50">
      <div className="container mx-auto px-4">
        <div className="max-w-2xl mx-auto">
          <Card className="border-2 border-orange-200 shadow-2xl">
            <CardHeader className="text-center space-y-3 bg-gradient-to-r from-orange-50 to-amber-50">
              <div className="w-16 h-16 bg-gradient-to-br from-orange-500 to-amber-500 rounded-full flex items-center justify-center mx-auto">
                <DollarSign className="w-8 h-8 text-white" />
              </div>
              <CardTitle className="text-3xl font-bold text-slate-800">
                Request Custom Invoice
              </CardTitle>
              <CardDescription className="text-lg text-slate-600">
                Fill out the form below and we'll send you a PayPal invoice for your custom service request.
              </CardDescription>
            </CardHeader>

            <CardContent className="p-8">
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Email Input */}
                <div className="space-y-2">
                  <label htmlFor="customerEmail" className="text-sm font-semibold text-slate-700">
                    Your Email Address *
                  </label>
                  <Input
                    id="customerEmail"
                    name="customerEmail"
                    type="email"
                    placeholder="your.email@example.com"
                    value={formData.customerEmail}
                    onChange={handleChange}
                    className="h-12 border-2 focus:border-orange-500"
                    required
                  />
                </div>

                {/* Description */}
                <div className="space-y-2">
                  <label htmlFor="description" className="text-sm font-semibold text-slate-700">
                    Service Description *
                  </label>
                  <Textarea
                    id="description"
                    name="description"
                    placeholder="Describe the service you need (e.g., Registration fee, Monthly tuition, Special program)..."
                    value={formData.description}
                    onChange={handleChange}
                    className="min-h-32 border-2 focus:border-orange-500"
                    required
                  />
                </div>

                {/* Amount */}
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
                      className="h-12 pl-8 border-2 focus:border-orange-500"
                      required
                    />
                  </div>
                </div>

                {/* Submit Button */}
                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full h-14 bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold text-lg rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105"
                >
                  {isSubmitting ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                      Creating Invoice...
                    </>
                  ) : (
                    <>
                      <Send className="w-5 h-5 mr-2" />
                      Create Invoice
                    </>
                  )}
                </Button>

                {/* Info Text */}
                <div className="flex items-start space-x-2 text-sm text-slate-600 bg-blue-50 p-4 rounded-lg">
                  <CheckCircle className="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" />
                  <p>
                    After submitting, you'll receive an email with a secure PayPal payment link. 
                    You can pay directly through PayPal without creating an account.
                  </p>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
};

export default PayPalInvoice;