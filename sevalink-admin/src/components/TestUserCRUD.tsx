import React, { useState, useEffect } from "react";

import TestUserForm from "./TestUserForm";
import TestUserList from "./TestUserList";
import { AlertCircle } from "lucide-react";

interface TestUser {
  id?: number;
  name: string;
  email: string;
  createdDate?: string;
}

const API_URL = "http://localhost:8080/api/test-users";

export default function TestUserCRUD() {
  const [users, setUsers] = useState<TestUser[]>([]);
  const [editingUser, setEditingUser] = useState<TestUser | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch all users
  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(API_URL);
      if (!response.ok)
        throw new Error(`HTTP error! status: ${response.status}`);
      const data = await response.json();
      setUsers(data);
    } catch (err) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to fetch users";
      setError(errorMsg);
      console.error("Fetch error:", err);
    } finally {
      setLoading(false);
    }
  };

  // Initial fetch
  useEffect(() => {
    fetchUsers();
  }, []);

  // Create user
  const handleCreate = async (userData: TestUser) => {
    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(userData),
      });
      if (!response.ok)
        throw new Error(`HTTP error! status: ${response.status}`);
      const newUser = await response.json();
      setUsers([...users, newUser]);
      setError(null);
    } catch (err) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to create user";
      setError(errorMsg);
      console.error("Create error:", err);
    }
  };

  // Update user
  const handleUpdate = async (userData: TestUser) => {
    if (!editingUser?.id) return;
    try {
      const response = await fetch(`${API_URL}/${editingUser.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(userData),
      });
      if (!response.ok)
        throw new Error(`HTTP error! status: ${response.status}`);
      const updatedUser = await response.json();
      setUsers(users.map((u) => (u.id === editingUser.id ? updatedUser : u)));
      setEditingUser(null);
      setError(null);
    } catch (err) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to update user";
      setError(errorMsg);
      console.error("Update error:", err);
    }
  };

  // Delete user
  const handleDelete = async (id: number) => {
    if (!confirm("Are you sure you want to delete this user?")) return;
    try {
      const response = await fetch(`${API_URL}/${id}`, {
        method: "DELETE",
      });
      if (!response.ok)
        throw new Error(`HTTP error! status: ${response.status}`);
      setUsers(users.filter((u) => u.id !== id));
      setError(null);
    } catch (err) {
      const errorMsg =
        err instanceof Error ? err.message : "Failed to delete user";
      setError(errorMsg);
      console.error("Delete error:", err);
    }
  };

  const handleSubmit = (userData: TestUser) => {
    if (editingUser) {
      handleUpdate(userData);
    } else {
      handleCreate(userData);
    }
  };

  return (
    <div className="max-w-6xl mx-auto">
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg flex items-start gap-3">
          <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />
          <div>
            <strong className="block">Error:</strong>
            <p className="text-sm">{error}</p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Form Section */}
        <div className="lg:col-span-1">
          <TestUserForm
            onSubmit={handleSubmit}
            editingUser={editingUser}
            onCancelEdit={() => setEditingUser(null)}
          />
        </div>

        {/* List Section */}
        <div className="lg:col-span-2">
          <TestUserList
            users={users}
            loading={loading}
            onEdit={setEditingUser}
            onDelete={handleDelete}
            onRefresh={fetchUsers}
          />
        </div>
      </div>
    </div>
  );
}
