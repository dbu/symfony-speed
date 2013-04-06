<?php

namespace Dbu\Bundle\CoreBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\Security\Core\SecurityContext;

class UserController extends Controller
{
    public function loginAction()
    {
        if ($this->get('request')->attributes->has(SecurityContext::AUTHENTICATION_ERROR)) {
            $error = $this->get('request')->attributes->get(SecurityContext::AUTHENTICATION_ERROR);
        } else {
            $error = $this->get('request')->getSession()->get(SecurityContext::AUTHENTICATION_ERROR);
        }

        return $this->render('DbuCoreBundle:User:login.html.twig', array(
            'last_username' => $this->get('request')->getSession()->get(SecurityContext::LAST_USERNAME),
            'error' => $error
        ));
    }

    public function showLoginBoxAction()
    {
        $response = $this->render('DbuCoreBundle:User:loginBox.html.twig', array());
        $response->setVary('Cookie', false); // true would mean to overwrite current vary setting
        $response->setMaxAge(0);
        $response->setPrivate();
        return $response;
    }
}
