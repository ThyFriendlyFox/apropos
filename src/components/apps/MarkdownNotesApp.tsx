"use client";

import React, { useState } from "react";
import { Plus, Trash2, Search, Tag, FileText, Check, Mic, Bookmark } from "lucide-react";

interface Note {
  id: string;
  title: string;
  body: string;
  category: string;
  updatedAt: string;
}

export default function MarkdownNotesApp() {
  const [notes, setNotes] = useState<Note[]>([
    {
      id: "1",
      title: "iOS Architecture Ideas",
      body: "# Key Components\n- App Runner Coordinator\n- Expo EAS Web Container bridge\n- Dynamic Island widgets\n- Offline SQLite state syncing",
      category: "Work",
      updatedAt: "10:42 AM"
    },
    {
      id: "2",
      title: "Grocery & Weekly Prep",
      body: "- [x] Organic Matcha\n- [x] Almond Milk\n- [ ] Greek Yogurt\n- [ ] Avocados",
      category: "Personal",
      updatedAt: "Yesterday"
    },
    {
      id: "3",
      title: "Reading Highlights: Clean Code",
      body: "> 'Simplicity is prerequisite for reliability.'\n\nFocus on small single-purpose modules and clean interfaces.",
      category: "Books",
      updatedAt: "Aug 28"
    }
  ]);

  const [selectedNoteId, setSelectedNoteId] = useState<string>(notes[0]?.id || "");
  const [searchQuery, setSearchQuery] = useState("");
  const [isEditing, setIsEditing] = useState(false);

  const selectedNote = notes.find((n) => n.id === selectedNoteId) || notes[0];

  const handleAddNote = () => {
    const newNote: Note = {
      id: Date.now().toString(),
      title: "New Note",
      body: "# Heading\n\nStart typing note...",
      category: "General",
      updatedAt: "Just now"
    };
    setNotes([newNote, ...notes]);
    setSelectedNoteId(newNote.id);
    setIsEditing(true);
  };

  const handleUpdateNote = (field: "title" | "body", val: string) => {
    setNotes((prev) =>
      prev.map((n) =>
        n.id === selectedNoteId ? { ...n, [field]: val, updatedAt: "Just now" } : n
      )
    );
  };

  const handleDeleteNote = (id: string) => {
    const remaining = notes.filter((n) => n.id !== id);
    setNotes(remaining);
    if (remaining.length > 0) {
      setSelectedNoteId(remaining[0].id);
    }
  };

  const filteredNotes = notes.filter(
    (n) =>
      n.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      n.body.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex flex-col h-full bg-zinc-950 text-zinc-100 p-4 font-sans select-none overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-zinc-800">
        <div>
          <div className="text-[11px] font-semibold text-purple-400 uppercase tracking-wider flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-purple-500" />
            Capacitor 6 / SQLite
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white">ObsidianMini</h1>
        </div>
        <button
          onClick={handleAddNote}
          className="w-8 h-8 rounded-full bg-purple-600 hover:bg-purple-500 text-white flex items-center justify-center shadow-lg transition active:scale-95"
        >
          <Plus className="w-5 h-5" />
        </button>
      </div>

      {/* Search Input */}
      <div className="mt-3 relative">
        <Search className="w-4 h-4 text-zinc-400 absolute left-3 top-2.5" />
        <input
          type="text"
          placeholder="Search notes or tags..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full bg-zinc-900 border border-zinc-800 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-purple-500"
        />
      </div>

      {/* Editor / Viewer */}
      {selectedNote ? (
        <div className="mt-3 flex-1 flex flex-col bg-zinc-900/60 border border-zinc-800/80 rounded-2xl p-3.5">
          <div className="flex items-center justify-between pb-2 border-b border-zinc-800 mb-2">
            <input
              type="text"
              value={selectedNote.title}
              onChange={(e) => handleUpdateNote("title", e.target.value)}
              className="bg-transparent text-base font-bold text-white focus:outline-none flex-1 mr-2"
            />
            <button
              onClick={() => handleDeleteNote(selectedNote.id)}
              className="text-zinc-500 hover:text-rose-400 p-1"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>

          <textarea
            value={selectedNote.body}
            onChange={(e) => handleUpdateNote("body", e.target.value)}
            className="flex-1 bg-transparent text-xs font-mono text-zinc-300 leading-relaxed focus:outline-none resize-none"
            placeholder="Type your markdown here..."
          />

          <div className="flex items-center justify-between pt-2 border-t border-zinc-800 text-[11px] text-zinc-500">
            <span>{selectedNote.category} • Updated {selectedNote.updatedAt}</span>
            <span className="font-mono text-purple-400">{selectedNote.body.length} chars</span>
          </div>
        </div>
      ) : null}

      {/* Note Tabs list below */}
      <div className="mt-3 flex gap-2 overflow-x-auto pb-1 scrollbar-none">
        {filteredNotes.map((note) => (
          <button
            key={note.id}
            onClick={() => setSelectedNoteId(note.id)}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium whitespace-nowrap transition border text-left ${
              selectedNoteId === note.id
                ? "bg-purple-950/80 border-purple-500 text-purple-200"
                : "bg-zinc-900 border-zinc-800 text-zinc-400 hover:text-white"
            }`}
          >
            {note.title}
          </button>
        ))}
      </div>
    </div>
  );
}
