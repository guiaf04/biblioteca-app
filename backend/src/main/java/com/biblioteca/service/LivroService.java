package com.biblioteca.service;

import com.biblioteca.model.Livro;
import com.biblioteca.repository.LivroRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class LivroService {
    
    @Autowired
    private LivroRepository livroRepository;
    
    public List<Livro> listarTodos() {
        return livroRepository.findAll();
    }
    
    public Optional<Livro> buscarPorId(Long id) {
        return livroRepository.findById(id);
    }
    
    public Optional<Livro> buscarPorIsbn(String isbn) {
        return livroRepository.findByIsbn(isbn);
    }
    
    public List<Livro> buscarPorTitulo(String titulo) {
        return livroRepository.findByTituloContainingIgnoreCase(titulo);
    }
    
    public List<Livro> buscarPorAutor(String autor) {
        return livroRepository.findByAutorContainingIgnoreCase(autor);
    }
    
    public List<Livro> buscarDisponiveis() {
        return livroRepository.findByDisponivel(true);
    }
    
    public List<Livro> buscarPorTermo(String termo) {
        return livroRepository.buscarPorTermo(termo);
    }
    
    public Livro salvar(Livro livro) {
        // Verificar se já existe um livro com o mesmo ISBN
        if (livro.getId() == null && livroRepository.findByIsbn(livro.getIsbn()).isPresent()) {
            throw new RuntimeException("Já existe um livro com este ISBN");
        }
        return livroRepository.save(livro);
    }
    
    public Livro atualizar(Long id, Livro livroAtualizado) {
        Optional<Livro> livroExistente = livroRepository.findById(id);
        if (livroExistente.isPresent()) {
            Livro livro = livroExistente.get();
            
            // Verificar se o ISBN foi alterado e se já existe
            if (!livro.getIsbn().equals(livroAtualizado.getIsbn())) {
                Optional<Livro> livroComMesmoIsbn = livroRepository.findByIsbn(livroAtualizado.getIsbn());
                if (livroComMesmoIsbn.isPresent() && !livroComMesmoIsbn.get().getId().equals(id)) {
                    throw new RuntimeException("Já existe um livro com este ISBN");
                }
            }
            
            livro.setTitulo(livroAtualizado.getTitulo());
            livro.setAutor(livroAtualizado.getAutor());
            livro.setIsbn(livroAtualizado.getIsbn());
            livro.setAnoPublicacao(livroAtualizado.getAnoPublicacao());
            livro.setEditora(livroAtualizado.getEditora());
            livro.setDescricao(livroAtualizado.getDescricao());
            livro.setDisponivel(livroAtualizado.getDisponivel());
            
            return livroRepository.save(livro);
        }
        throw new RuntimeException("Livro não encontrado");
    }
    
    public void deletar(Long id) {
        if (livroRepository.existsById(id)) {
            livroRepository.deleteById(id);
        } else {
            throw new RuntimeException("Livro não encontrado");
        }
    }
    
    public long contarTotal() {
        return livroRepository.count();
    }
    
    public long contarDisponiveis() {
        return livroRepository.findByDisponivel(true).size();
    }
}

