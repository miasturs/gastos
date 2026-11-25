window.CategoriasService = {
  async list() { return await DB.getAll('categorias'); },
  async create(cat) { await DB.put('categorias', cat.id, cat); },
  async update(cat) { await DB.put('categorias', cat.id, cat); },
  async delete(id) { await DB.del('categorias', id); },
  async findById(id) {
    const cats = await this.list();
    return cats.find(c => c.id === id);
  }
};