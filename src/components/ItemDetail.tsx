import { useParams, useNavigate } from 'react-router';
import { marketplaceItems } from '../lib/mockData';
import { MapPin, Calendar, Package, ArrowLeft, MessageCircle } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

export function ItemDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const item = marketplaceItems.find(i => i.id === id);

  if (!item) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8 text-center">
        <p className="text-gray-600">Item not found</p>
        <button
          onClick={() => navigate('/')}
          className="mt-4 text-red-700 hover:underline"
        >
          Go back to marketplace
        </button>
      </div>
    );
  }

  const handleContact = () => {
    toast.success('Contact information would be shown here in the full app');
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
      {/* Back Button */}
      <button
        onClick={() => navigate(-1)}
        className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4"
      >
        <ArrowLeft className="w-5 h-5" />
        Back
      </button>

      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        {/* Image */}
        <div className="aspect-[4/3] bg-gray-100">
          <img
            src={item.image}
            alt={item.title}
            className="w-full h-full object-cover"
          />
        </div>

        {/* Content */}
        <div className="p-6">
          {/* Price and Title */}
          <div className="mb-4">
            <p className="text-3xl font-bold text-red-700 mb-2">
              ${item.price}
            </p>
            <h1 className="text-2xl font-bold mb-2">{item.title}</h1>
          </div>

          {/* Details Grid */}
          <div className="grid grid-cols-2 gap-4 mb-6 p-4 bg-gray-50 rounded-lg">
            <div className="flex items-center gap-2">
              <Package className="w-5 h-5 text-gray-500" />
              <div>
                <p className="text-xs text-gray-500">Condition</p>
                <p className="font-medium">{item.condition}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <MapPin className="w-5 h-5 text-gray-500" />
              <div>
                <p className="text-xs text-gray-500">Location</p>
                <p className="font-medium">{item.location}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Calendar className="w-5 h-5 text-gray-500" />
              <div>
                <p className="text-xs text-gray-500">Posted</p>
                <p className="font-medium">
                  {new Date(item.createdAt).toLocaleDateString()}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Package className="w-5 h-5 text-gray-500" />
              <div>
                <p className="text-xs text-gray-500">Category</p>
                <p className="font-medium">{item.category}</p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div className="mb-6">
            <h2 className="font-semibold mb-2">Description</h2>
            <p className="text-gray-700 whitespace-pre-line">{item.description}</p>
          </div>

          {/* Seller Info */}
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <h3 className="font-semibold mb-2">Seller</h3>
            <p className="text-gray-700">{item.seller}</p>
          </div>

          {/* Contact Button */}
          <button
            onClick={handleContact}
            className="w-full bg-red-700 text-white py-3 rounded-lg font-medium hover:bg-red-800 transition-colors flex items-center justify-center gap-2"
          >
            <MessageCircle className="w-5 h-5" />
            Contact Seller
          </button>
        </div>
      </div>
    </div>
  );
}
