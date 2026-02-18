import { useState } from 'react';
import { Link } from 'react-router';
import { lostFoundItems, lostFoundCategories } from '../lib/mockData';
import { Search, MapPin, AlertCircle, CheckCircle } from 'lucide-react';

export function LostAndFound() {
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedType, setSelectedType] = useState<'all' | 'lost' | 'found'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredItems = lostFoundItems.filter(item => {
    const matchesCategory = selectedCategory === 'All' || item.category === selectedCategory;
    const matchesType = selectedType === 'all' || item.type === selectedType;
    const matchesSearch = item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         item.description.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesType && matchesSearch;
  });

  return (
    <div className="max-w-7xl mx-auto px-4 py-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold mb-2">Lost & Found</h2>
        <p className="text-gray-600">Help fellow students reunite with their belongings</p>
      </div>

      {/* Type Filter */}
      <div className="mb-4">
        <div className="flex gap-2">
          <button
            onClick={() => setSelectedType('all')}
            className={`flex-1 py-3 rounded-lg transition-colors ${
              selectedType === 'all'
                ? 'bg-red-700 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setSelectedType('lost')}
            className={`flex-1 py-3 rounded-lg transition-colors flex items-center justify-center gap-2 ${
              selectedType === 'lost'
                ? 'bg-orange-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            <AlertCircle className="w-4 h-4" />
            Lost
          </button>
          <button
            onClick={() => setSelectedType('found')}
            className={`flex-1 py-3 rounded-lg transition-colors flex items-center justify-center gap-2 ${
              selectedType === 'found'
                ? 'bg-green-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            <CheckCircle className="w-4 h-4" />
            Found
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search lost & found items..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent"
          />
        </div>
      </div>

      {/* Category Filter */}
      <div className="mb-6 overflow-x-auto">
        <div className="flex gap-2 pb-2">
          {lostFoundCategories.map(category => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${
                selectedCategory === category
                  ? 'bg-red-700 text-white'
                  : 'bg-white text-gray-700 border border-gray-300 hover:border-red-700'
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </div>

      {/* Items List */}
      <div className="space-y-4">
        {filteredItems.map(item => (
          <div
            key={item.id}
            className="bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="flex gap-4 p-4">
              <div className="w-24 h-24 flex-shrink-0 bg-gray-100 rounded-lg overflow-hidden">
                <img
                  src={item.image}
                  alt={item.title}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <h3 className="font-semibold">{item.title}</h3>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium whitespace-nowrap ${
                    item.type === 'lost'
                      ? 'bg-orange-100 text-orange-700'
                      : 'bg-green-100 text-green-700'
                  }`}>
                    {item.type === 'lost' ? 'Lost' : 'Found'}
                  </span>
                </div>
                <p className="text-sm text-gray-600 mb-2 line-clamp-2">
                  {item.description}
                </p>
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
                  <div className="flex items-center gap-1">
                    <MapPin className="w-3 h-3" />
                    <span>{item.location}</span>
                  </div>
                  <span>Posted by {item.poster}</span>
                  <span>{new Date(item.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredItems.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500">No items found matching your criteria</p>
        </div>
      )}
    </div>
  );
}
