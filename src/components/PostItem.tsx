import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Camera, DollarSign, MapPin, Tag } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

export function PostItem() {
  const navigate = useNavigate();
  const [listingType, setListingType] = useState<'marketplace' | 'lost' | 'found'>('marketplace');
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    price: '',
    category: '',
    condition: 'Good',
    location: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Simulate posting
    toast.success('Item posted successfully!');
    
    // Navigate based on listing type
    if (listingType === 'marketplace') {
      navigate('/');
    } else {
      navigate('/lost-found');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-6">
      <h2 className="text-2xl font-bold mb-6">Post an Item</h2>

      {/* Listing Type Selector */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Listing Type</label>
        <div className="grid grid-cols-3 gap-2">
          <button
            type="button"
            onClick={() => setListingType('marketplace')}
            className={`py-3 rounded-lg transition-colors ${
              listingType === 'marketplace'
                ? 'bg-red-700 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            For Sale
          </button>
          <button
            type="button"
            onClick={() => setListingType('lost')}
            className={`py-3 rounded-lg transition-colors ${
              listingType === 'lost'
                ? 'bg-orange-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            Lost
          </button>
          <button
            type="button"
            onClick={() => setListingType('found')}
            className={`py-3 rounded-lg transition-colors ${
              listingType === 'found'
                ? 'bg-green-600 text-white'
                : 'bg-white text-gray-700 border border-gray-300'
            }`}
          >
            Found
          </button>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Image Upload */}
        <div>
          <label className="block text-sm font-medium mb-2">Photo</label>
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-red-700 transition-colors cursor-pointer">
            <Camera className="w-12 h-12 mx-auto text-gray-400 mb-2" />
            <p className="text-sm text-gray-600">Click to upload a photo</p>
            <p className="text-xs text-gray-500 mt-1">Recommended: Square image, at least 800x800px</p>
          </div>
        </div>

        {/* Title */}
        <div>
          <label htmlFor="title" className="block text-sm font-medium mb-2">
            Title *
          </label>
          <input
            type="text"
            id="title"
            name="title"
            value={formData.title}
            onChange={handleInputChange}
            required
            placeholder={
              listingType === 'marketplace'
                ? 'e.g., Chemistry Textbook 11th Edition'
                : listingType === 'lost'
                ? 'e.g., Lost Black Backpack'
                : 'e.g., Found AirPods'
            }
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent"
          />
        </div>

        {/* Description */}
        <div>
          <label htmlFor="description" className="block text-sm font-medium mb-2">
            Description *
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            required
            rows={4}
            placeholder="Provide details about the item..."
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent resize-none"
          />
        </div>

        {/* Price (only for marketplace) */}
        {listingType === 'marketplace' && (
          <div>
            <label htmlFor="price" className="block text-sm font-medium mb-2">
              Price *
            </label>
            <div className="relative">
              <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="number"
                id="price"
                name="price"
                value={formData.price}
                onChange={handleInputChange}
                required={listingType === 'marketplace'}
                min="0"
                step="0.01"
                placeholder="0.00"
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent"
              />
            </div>
          </div>
        )}

        {/* Category */}
        <div>
          <label htmlFor="category" className="block text-sm font-medium mb-2">
            Category *
          </label>
          <div className="relative">
            <Tag className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleInputChange}
              required
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent appearance-none"
            >
              <option value="">Select a category</option>
              {listingType === 'marketplace' ? (
                <>
                  <option value="Textbooks">Textbooks</option>
                  <option value="Electronics">Electronics</option>
                  <option value="Furniture">Furniture</option>
                  <option value="Clothing">Clothing</option>
                  <option value="Other">Other</option>
                </>
              ) : (
                <>
                  <option value="Electronics">Electronics</option>
                  <option value="Bags">Bags</option>
                  <option value="Keys">Keys</option>
                  <option value="ID/Cards">ID/Cards</option>
                  <option value="Clothing">Clothing</option>
                  <option value="Other">Other</option>
                </>
              )}
            </select>
          </div>
        </div>

        {/* Condition (only for marketplace) */}
        {listingType === 'marketplace' && (
          <div>
            <label htmlFor="condition" className="block text-sm font-medium mb-2">
              Condition *
            </label>
            <select
              id="condition"
              name="condition"
              value={formData.condition}
              onChange={handleInputChange}
              required={listingType === 'marketplace'}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent"
            >
              <option value="New">New</option>
              <option value="Like New">Like New</option>
              <option value="Good">Good</option>
              <option value="Fair">Fair</option>
            </select>
          </div>
        )}

        {/* Location */}
        <div>
          <label htmlFor="location" className="block text-sm font-medium mb-2">
            Location *
          </label>
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              id="location"
              name="location"
              value={formData.location}
              onChange={handleInputChange}
              required
              placeholder="e.g., Student Center, Blanton Hall"
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-700 focus:border-transparent"
            />
          </div>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="w-full bg-red-700 text-white py-3 rounded-lg font-medium hover:bg-red-800 transition-colors"
        >
          Post Item
        </button>
      </form>
    </div>
  );
}
