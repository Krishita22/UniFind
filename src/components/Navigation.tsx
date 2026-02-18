import { Link, useLocation } from 'react-router';
import { Home, Search, PlusCircle, BookOpen } from 'lucide-react';

export function Navigation() {
  const location = useLocation();
  
  const isActive = (path: string) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <>
      {/* Top Header */}
      <header className="bg-red-700 text-white sticky top-0 z-50 shadow-md">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <Link to="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center">
                <span className="text-red-700 font-bold text-lg">U</span>
              </div>
              <div>
                <h1 className="font-bold text-xl">UniFind</h1>
                <p className="text-xs text-red-100">Montclair State</p>
              </div>
            </Link>
          </div>
        </div>
      </header>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-around items-center py-2">
            <Link
              to="/"
              className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                isActive('/') && location.pathname === '/'
                  ? 'text-red-700'
                  : 'text-gray-600'
              }`}
            >
              <Home className="w-6 h-6" />
              <span className="text-xs">Shop</span>
            </Link>
            
            <Link
              to="/lost-found"
              className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                isActive('/lost-found')
                  ? 'text-red-700'
                  : 'text-gray-600'
              }`}
            >
              <Search className="w-6 h-6" />
              <span className="text-xs">Lost & Found</span>
            </Link>
            
            <Link
              to="/post"
              className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                isActive('/post')
                  ? 'text-red-700'
                  : 'text-gray-600'
              }`}
            >
              <PlusCircle className="w-6 h-6" />
              <span className="text-xs">Post</span>
            </Link>
            
            <Link
              to="/docs"
              className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                isActive('/docs')
                  ? 'text-red-700'
                  : 'text-gray-600'
              }`}
            >
              <BookOpen className="w-6 h-6" />
              <span className="text-xs">Docs</span>
            </Link>
          </div>
        </div>
      </nav>
    </>
  );
}