package com.biblioteca.repository;

import com.biblioteca.model.Livro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LivroRepository extends JpaRepository<Livro, Long> {
    
    Optional<Livro> findByIsbn(String isbn);
    
    List<Livro> findByTituloContainingIgnoreCase(String titulo);
    
    List<Livro> findByAutorContainingIgnoreCase(String autor);
    
    List<Livro> findByDisponivel(Boolean disponivel);
    
    @Query("SELECT l FROM Livro l WHERE " +
           "LOWER(l.titulo) LIKE LOWER(CONCAT('%', :termo, '%')) OR " +
           "LOWER(l.autor) LIKE LOWER(CONCAT('%', :termo, '%')) OR " +
           "LOWER(l.editora) LIKE LOWER(CONCAT('%', :termo, '%'))")
    List<Livro> buscarPorTermo(@Param("termo") String termo);
}

