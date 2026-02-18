import { useState } from 'react';
import { Package, AlertCircle } from 'lucide-react';

export function MyListings() {
  const [activeTab, setActiveTab] = useState<'marketplace' | 'lostfound'>('marketplace');

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
      <h2 className="text-2xl font-bold mb-6">My Listings</h2>

      {/* Tabs */}
      <div className="mb-6">
        <div className="flex gap-2 border-b border-gray-200">
          <button
            onClick={() => setActiveTab('marketplace')}
            className={`px-4 py-3 font-medium transition-colors ${
              activeTab === 'marketplace'
                ? 'text-red-700 border-b-2 border-red-700'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Marketplace Items
          </button>
          <button
            onClick={() => setActiveTab('lostfound')}
            className={`px-4 py-3 font-medium transition-colors ${
              activeTab === 'lostfound'
                ? 'text-red-700 border-b-2 border-red-700'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Lost & Found
          </button>
        </div>
      </div>

      {/* Empty State */}
      <div className="text-center py-12">
        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          {activeTab === 'marketplace' ? (
            <Package className="w-8 h-8 text-gray-400" />
          ) : (
            <AlertCircle className="w-8 h-8 text-gray-400" />
          )}
        </div>
        <h3 className="font-semibold mb-2">No items yet</h3>
        <p className="text-gray-600 mb-6">
          {activeTab === 'marketplace'
            ? 'You haven\'t posted any items for sale yet.'
            : 'You haven\'t posted any lost or found items yet.'}
        </p>
        <p className="text-sm text-gray-500">
          Your posted items will appear here
        </p>
      </div>
    </div>
  );
}
