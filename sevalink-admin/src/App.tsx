import "./App.css";
import TestUserCRUD from "./components/TestUserCRUD";
import { Users } from "lucide-react";

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      <header className="bg-gradient-to-r from-slate-600 via-slate-700 to-slate-800 text-white p-6 shadow-lg border-b border-slate-500">
        <div className="flex items-center gap-3">
          <Users className="w-8 h-8" />
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              SevaLink Admin
            </h1>
            <p className="text-slate-300 text-sm mt-1">
              Spring Boot Backend Testing Application
            </p>
          </div>
        </div>
      </header>
      <main className="p-8">
        <TestUserCRUD />
      </main>
    </div>
  );
}

export default App;
