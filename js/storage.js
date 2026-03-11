/**
 * storage.js
 * Gestión de datos con localStorage
 */

const STORAGE_KEYS = {
  STUDENTS: 'sge_students',
  COURSES: 'sge_courses',
  GRADES: 'sge_grades',
};

const Storage = {
  /** Obtiene un array de registros por clave */
  getAll(key) {
    try {
      const data = localStorage.getItem(key);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  /** Guarda un array completo */
  saveAll(key, data) {
    localStorage.setItem(key, JSON.stringify(data));
  },

  /** Agrega un elemento, generando id automático */
  add(key, item) {
    const items = this.getAll(key);
    item.id = item.id || `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
    items.push(item);
    this.saveAll(key, items);
    return item;
  },

  /** Actualiza un elemento por id */
  update(key, id, updated) {
    const items = this.getAll(key);
    const idx = items.findIndex(i => i.id === id);
    if (idx !== -1) {
      items[idx] = { ...items[idx], ...updated, id };
      this.saveAll(key, items);
      return items[idx];
    }
    return null;
  },

  /** Elimina un elemento por id */
  remove(key, id) {
    const items = this.getAll(key);
    const filtered = items.filter(i => i.id !== id);
    this.saveAll(key, filtered);
  },

  /** Busca un elemento por id */
  findById(key, id) {
    return this.getAll(key).find(i => i.id === id) || null;
  },
};
