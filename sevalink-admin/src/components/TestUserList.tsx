import React from "react";
import { RotateCcw, Edit2, Trash2, Users, Mail, Clock } from "lucide-react";

interface TestUser {
  id?: number;
  name: string;
  email: string;
  createdDate?: string;
}

interface TestUserListProps {
  users: TestUser[];
  loading: boolean;
  onEdit: (user: TestUser) => void;
  onDelete: (id: number) => void;
  onRefresh: () => void;
}

export default function TestUserList({
  users,
  loading,
  onEdit,
  onDelete,
  onRefresh,
}: TestUserListProps) {
  const formatDate = (dateString?: string) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="bg-white p-6 rounded-xl shadow-md border border-slate-100 hover:shadow-lg transition-shadow">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <div className="w-10 h-10 bg-cyan-100 rounded-lg flex items-center justify-center">
            <Users className="w-5 h-5 text-cyan-600" />
          </div>
          <h2 className="text-2xl font-bold text-slate-800">Users List</h2>
        </div>
        <button
          onClick={onRefresh}
          disabled={loading}
          className="flex items-center gap-2 bg-gradient-to-r from-cyan-500 to-cyan-600 text-white font-semibold py-2 px-4 rounded-lg hover:from-cyan-600 hover:to-cyan-700 transition-all shadow-sm hover:shadow-md disabled:from-slate-400 disabled:to-slate-400"
        >
          <RotateCcw className="w-4 h-4" />
          {loading ? "Loading..." : "Refresh"}
        </button>
      </div>

      {loading ? (
        <div className="text-center py-12">
          <div className="inline-block">
            <RotateCcw className="w-8 h-8 text-slate-400 animate-spin mb-2" />
            <p className="text-slate-500">Loading users...</p>
          </div>
        </div>
      ) : users.length === 0 ? (
        <div className="text-center py-12">
          <Users className="w-12 h-12 text-slate-300 mx-auto mb-3" />
          <p className="text-slate-500 text-lg">
            No users found. Create one to get started!
          </p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-gradient-to-r from-slate-50 to-slate-100 border-b border-slate-200">
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">
                  ID
                </th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">
                  <div className="flex items-center gap-1">
                    <Users className="w-4 h-4" /> Name
                  </div>
                </th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">
                  <div className="flex items-center gap-1">
                    <Mail className="w-4 h-4" /> Email
                  </div>
                </th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">
                  <div className="flex items-center gap-1">
                    <Clock className="w-4 h-4" /> Created
                  </div>
                </th>
                <th className="px-4 py-3 text-center text-sm font-semibold text-slate-700">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr
                  key={user.id}
                  className="border-b border-slate-200 hover:bg-indigo-50 transition-colors"
                >
                  <td className="px-4 py-3 text-sm font-medium text-slate-900">
                    #{user.id}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-700">
                    {user.name}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-600">
                    {user.email}
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-500">
                    {formatDate(user.createdDate)}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2 justify-center">
                      <button
                        onClick={() => onEdit(user)}
                        className="flex items-center gap-1 bg-amber-100 text-amber-700 font-medium py-1.5 px-3 rounded-lg hover:bg-amber-200 transition-colors text-sm"
                        title="Edit user"
                      >
                        <Edit2 className="w-4 h-4" />
                        Edit
                      </button>
                      <button
                        onClick={() => user.id && onDelete(user.id)}
                        className="flex items-center gap-1 bg-red-100 text-red-700 font-medium py-1.5 px-3 rounded-lg hover:bg-red-200 transition-colors text-sm"
                        title="Delete user"
                      >
                        <Trash2 className="w-4 h-4" />
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="mt-6 pt-4 border-t border-slate-200 text-sm text-slate-600">
        Total Users:{" "}
        <span className="font-semibold text-slate-900">{users.length}</span>
      </div>
    </div>
  );
}
