import React, { useState, useEffect } from "react";
import { Save, X, Plus } from "lucide-react";

interface TestUser {
  id?: number;
  name: string;
  email: string;
  createdDate?: string;
}

interface TestUserFormProps {
  onSubmit: (user: TestUser) => void;
  editingUser: TestUser | null;
  onCancelEdit: () => void;
}

export default function TestUserForm({
  onSubmit,
  editingUser,
  onCancelEdit,
}: TestUserFormProps) {
  const [formData, setFormData] = useState<TestUser>({
    name: "",
    email: "",
  });

  useEffect(() => {
    if (editingUser) {
      setFormData(editingUser);
    } else {
      setFormData({ name: "", email: "" });
    }
  }, [editingUser]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.email.trim()) {
      alert("Please fill in all fields");
      return;
    }
    onSubmit(formData);
    setFormData({ name: "", email: "" });
  };

  const handleCancel = () => {
    setFormData({ name: "", email: "" });
    onCancelEdit();
  };

  return (
    <div className="bg-white p-6 rounded-xl shadow-md border border-slate-100 hover:shadow-lg transition-shadow">
      <div className="flex items-center gap-2 mb-4">
        {editingUser ? (
          <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
            <Save className="w-5 h-5 text-amber-600" />
          </div>
        ) : (
          <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
            <Plus className="w-5 h-5 text-indigo-600" />
          </div>
        )}
        <h2 className="text-2xl font-bold text-slate-800">
          {editingUser ? "Edit User" : "Create New User"}
        </h2>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="name"
            className="block text-sm font-semibold text-slate-700 mb-2"
          >
            Full Name
          </label>
          <input
            id="name"
            type="text"
            name="name"
            value={formData.name}
            onChange={handleChange}
            placeholder="John Doe"
            className="w-full px-4 py-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-slate-50 hover:bg-white transition-colors"
          />
        </div>

        <div>
          <label
            htmlFor="email"
            className="block text-sm font-semibold text-slate-700 mb-2"
          >
            Email Address
          </label>
          <input
            id="email"
            type="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            placeholder="john@example.com"
            className="w-full px-4 py-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-slate-50 hover:bg-white transition-colors"
          />
        </div>

        <div className="flex gap-3 pt-4">
          <button
            type="submit"
            className="flex-1 bg-gradient-to-r from-indigo-500 to-indigo-600 text-white font-semibold py-2.5 px-4 rounded-lg hover:from-indigo-600 hover:to-indigo-700 transition-all shadow-sm hover:shadow-md flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            {editingUser ? "Update User" : "Create User"}
          </button>
          {editingUser && (
            <button
              type="button"
              onClick={handleCancel}
              className="flex-1 bg-slate-200 text-slate-700 font-semibold py-2.5 px-4 rounded-lg hover:bg-slate-300 transition-all flex items-center justify-center gap-2"
            >
              <X className="w-4 h-4" />
              Cancel
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
