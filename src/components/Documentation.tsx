import { BookOpen, ShoppingBag, Search, PlusCircle, Shield, MessageCircle, HelpCircle } from 'lucide-react';

export function Documentation() {
  return (
    <div className="max-w-4xl mx-auto px-4 py-6 pb-24">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-3">
          <div className="w-12 h-12 bg-red-700 rounded-lg flex items-center justify-center">
            <BookOpen className="w-7 h-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">Documentation</h1>
            <p className="text-gray-600">Everything you need to know about UniFind</p>
          </div>
        </div>
      </div>

      {/* Quick Start */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">1</span>
          Getting Started
        </h2>
        <div className="bg-white rounded-lg p-6 shadow-sm">
          <p className="text-gray-700 mb-4">
            Welcome to UniFind, Montclair State University's marketplace and lost & found platform! 
            UniFind makes it easy to buy, sell, and trade items with fellow students, as well as help 
            reunite lost belongings with their owners.
          </p>
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-sm text-red-800">
              <strong>Note:</strong> UniFind is designed for the Montclair State community. 
              Always meet in safe, public locations on campus when exchanging items.
            </p>
          </div>
        </div>
      </section>

      {/* Marketplace Guide */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">2</span>
          Using the Marketplace
        </h2>
        <div className="space-y-4">
          {/* Browse Items */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <ShoppingBag className="w-5 h-5 text-blue-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Browsing Items</h3>
                <ul className="text-sm text-gray-700 space-y-2">
                  <li>• Use the search bar to find specific items</li>
                  <li>• Filter by categories: Textbooks, Electronics, Furniture, Clothing, and more</li>
                  <li>• Tap on any item to view full details, pricing, and seller information</li>
                  <li>• Check the item condition and location before contacting the seller</li>
                </ul>
              </div>
            </div>
          </div>

          {/* Posting Items */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <PlusCircle className="w-5 h-5 text-green-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Posting Items for Sale</h3>
                <ol className="text-sm text-gray-700 space-y-2">
                  <li>1. Navigate to the "Post" tab</li>
                  <li>2. Select "For Sale" as the listing type</li>
                  <li>3. Add a clear photo of your item</li>
                  <li>4. Write a descriptive title and detailed description</li>
                  <li>5. Set a fair price based on item condition</li>
                  <li>6. Select the appropriate category</li>
                  <li>7. Specify item condition (New, Like New, Good, Fair)</li>
                  <li>8. Add your campus location for pickup</li>
                  <li>9. Click "Post Item" to publish your listing</li>
                </ol>
              </div>
            </div>
          </div>

          {/* Contacting Sellers */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <MessageCircle className="w-5 h-5 text-purple-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Contacting Sellers</h3>
                <ul className="text-sm text-gray-700 space-y-2">
                  <li>• Click "Contact Seller" on any item detail page</li>
                  <li>• Be polite and respectful in all communications</li>
                  <li>• Arrange safe meetup locations on campus</li>
                  <li>• Inspect items before completing transactions</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Lost & Found Guide */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">3</span>
          Lost & Found
        </h2>
        <div className="space-y-4">
          {/* Reporting Lost Items */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Search className="w-5 h-5 text-orange-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Reporting Lost Items</h3>
                <ol className="text-sm text-gray-700 space-y-2">
                  <li>1. Go to the "Post" tab</li>
                  <li>2. Select "Lost" as the listing type</li>
                  <li>3. Add a photo if available (or similar item photo)</li>
                  <li>4. Provide a detailed description of the item</li>
                  <li>5. Specify where and when you lost it</li>
                  <li>6. Select the appropriate category</li>
                  <li>7. Post the listing to alert the community</li>
                </ol>
                <div className="mt-3 bg-orange-50 rounded p-3">
                  <p className="text-xs text-orange-800">
                    <strong>Tip:</strong> Check the Lost & Found regularly - someone may have already found your item!
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Reporting Found Items */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Search className="w-5 h-5 text-green-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Reporting Found Items</h3>
                <ol className="text-sm text-gray-700 space-y-2">
                  <li>1. Navigate to the "Post" tab</li>
                  <li>2. Select "Found" as the listing type</li>
                  <li>3. Add a photo of the found item</li>
                  <li>4. Describe the item and where you found it</li>
                  <li>5. Specify the location where it can be retrieved</li>
                  <li>6. Wait for the owner to contact you</li>
                  <li>7. Verify ownership before returning the item</li>
                </ol>
                <div className="mt-3 bg-green-50 rounded p-3">
                  <p className="text-xs text-green-800">
                    <strong>Tip:</strong> For valuable items, ask the claimant to describe specific details to verify ownership.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Lost & Found Filters */}
          <div className="bg-white rounded-lg p-6 shadow-sm">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                <Search className="w-5 h-5 text-blue-700" />
              </div>
              <div>
                <h3 className="font-semibold mb-2">Searching Lost & Found</h3>
                <ul className="text-sm text-gray-700 space-y-2">
                  <li>• Filter by "Lost" or "Found" items</li>
                  <li>• Use category filters to narrow your search</li>
                  <li>• Search by keywords in the search bar</li>
                  <li>• Check location details for where items were lost/found</li>
                  <li>• Contact the poster if you recognize an item</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Safety Guidelines */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">4</span>
          Safety Guidelines
        </h2>
        <div className="bg-white rounded-lg p-6 shadow-sm">
          <div className="flex items-start gap-3 mb-4">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center flex-shrink-0">
              <Shield className="w-5 h-5 text-red-700" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold mb-3">Stay Safe on Campus</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>✓ <strong>Meet in Public:</strong> Always arrange meetups in well-lit, populated areas on campus (Student Center, Library, Dining Halls)</li>
                <li>✓ <strong>Bring a Friend:</strong> Consider having someone accompany you during item exchanges</li>
                <li>✓ <strong>Inspect Items:</strong> Thoroughly check items before completing purchases</li>
                <li>✓ <strong>Trust Your Instincts:</strong> If something feels off, don't proceed with the transaction</li>
                <li>✓ <strong>Verify Identity:</strong> For lost & found, verify ownership before returning items</li>
                <li>✓ <strong>Report Issues:</strong> Contact Campus Security if you experience any problems</li>
                <li>✓ <strong>No Personal Info:</strong> Avoid sharing sensitive personal information publicly</li>
              </ul>
            </div>
          </div>
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mt-4">
            <p className="text-sm text-red-800">
              <strong>Campus Security:</strong> (973) 655-5222 | In case of emergency, always dial 911
            </p>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">5</span>
          Frequently Asked Questions
        </h2>
        <div className="space-y-3">
          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              Is UniFind only for Montclair State students?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              Yes, UniFind is designed exclusively for the Montclair State University community. 
              This ensures a safe and trusted environment for all transactions.
            </div>
          </details>

          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              How do I edit or delete my listings?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              Go to "My Items" in the bottom navigation to view all your active listings. 
              From there, you can edit details or mark items as sold/resolved.
            </div>
          </details>

          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              What payment methods are accepted?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              UniFind doesn't process payments directly. Buyers and sellers arrange payment 
              methods between themselves. Common options include cash, Venmo, or Zelle.
            </div>
          </details>

          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              What if I find something valuable?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              For valuable items (laptops, phones, wallets with ID), consider also reporting 
              them to Campus Security or the Student Center's Lost & Found office. Post on 
              UniFind to help reach the owner quickly.
            </div>
          </details>

          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              Can I report inappropriate listings?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              Yes. If you see listings that violate community guidelines or appear suspicious, 
              please report them. We're committed to maintaining a safe marketplace for all students.
            </div>
          </details>

          <details className="bg-white rounded-lg shadow-sm">
            <summary className="p-4 cursor-pointer font-medium flex items-center gap-2 hover:bg-gray-50">
              <HelpCircle className="w-5 h-5 text-red-700 flex-shrink-0" />
              How long do listings stay active?
            </summary>
            <div className="px-4 pb-4 text-sm text-gray-700">
              Listings remain active until you mark them as sold/resolved or delete them. 
              We recommend updating your listings promptly when items are no longer available.
            </div>
          </details>
        </div>
      </section>

      {/* Best Practices */}
      <section className="mb-8">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">6</span>
          Best Practices
        </h2>
        <div className="bg-white rounded-lg p-6 shadow-sm">
          <h3 className="font-semibold mb-3">For Sellers</h3>
          <ul className="text-sm text-gray-700 space-y-2 mb-4">
            <li>• Take clear, well-lit photos from multiple angles</li>
            <li>• Be honest about item condition and any defects</li>
            <li>• Price items fairly based on condition and market value</li>
            <li>• Respond to inquiries promptly and professionally</li>
            <li>• Mark items as sold once transaction is complete</li>
          </ul>
          
          <h3 className="font-semibold mb-3 mt-6">For Buyers</h3>
          <ul className="text-sm text-gray-700 space-y-2">
            <li>• Ask questions before committing to purchase</li>
            <li>• Request additional photos if needed</li>
            <li>• Confirm item availability before arranging meetup</li>
            <li>• Bring exact change when possible</li>
            <li>• Leave feedback for sellers (coming soon!)</li>
          </ul>
        </div>
      </section>

      {/* Community Guidelines */}
      <section>
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
          <span className="w-8 h-8 bg-red-100 text-red-700 rounded-full flex items-center justify-center text-sm font-bold">7</span>
          Community Guidelines
        </h2>
        <div className="bg-white rounded-lg p-6 shadow-sm">
          <p className="text-sm text-gray-700 mb-4">
            UniFind is built on trust and respect within the Montclair State community. 
            Please adhere to these guidelines:
          </p>
          <ul className="text-sm text-gray-700 space-y-2">
            <li>✓ Be respectful and courteous in all interactions</li>
            <li>✓ Only post items you own or have permission to sell</li>
            <li>✓ Do not post prohibited items (weapons, drugs, alcohol, etc.)</li>
            <li>✓ Provide accurate descriptions and honest representations</li>
            <li>✓ Honor your commitments to buyers and sellers</li>
            <li>✓ Protect your own and others' privacy</li>
            <li>✓ Report suspicious activity or violations</li>
            <li>✓ Use the platform for its intended purpose only</li>
          </ul>
          <div className="bg-gray-50 rounded-lg p-4 mt-4">
            <p className="text-sm text-gray-700">
              By using UniFind, you agree to follow these guidelines and help maintain 
              a positive experience for all Montclair State students.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
